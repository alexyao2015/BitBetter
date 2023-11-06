using System;
using System.IO;
using System.Linq;
using System.Security.Cryptography.X509Certificates;
using Mono.Cecil;
using Mono.Cecil.Cil;
using Mono.Cecil.Rocks;

namespace bitwardenSelfLicensor
{
    class Program
    {
        static int Main(string[] args)
        {
            string cerFile;
            string corePath;

            if(args.Length >= 2) {
                cerFile = args[0];
                corePath = args[1];
            } else if (args.Length == 1) {
                cerFile = args[0];
                corePath = "/app/Core.dll";
            }
            else {
                cerFile = "/newLicensing.cer";
                corePath = "/app/Core.dll";
            }


            var module =  ModuleDefinition.ReadModule(new MemoryStream(File.ReadAllBytes(corePath)));
            var cert = File.ReadAllBytes(cerFile);

            var x = module.Resources.OfType<EmbeddedResource>()
                                    .Where(r => r.Name.Equals("Bit.Core.licensing.cer"))
                                    .First();

            Console.WriteLine(x.Name);

            var e = new EmbeddedResource("Bit.Core.licensing.cer", x.Attributes, cert);

            module.Resources.Add(e);
            module.Resources.Remove(x);

            var services = module.Types.Where(t => t.Namespace == "Bit.Core.Services");
            

            var type = services.First(t => t.Name == "LicensingService");

            var licensingType =  type.Resolve();

            var existingCert = new X509Certificate2(x.GetResourceData());

            Console.WriteLine($"Existing Cert Thumbprint: {existingCert.Thumbprint}");
            X509Certificate2 certificate = new X509Certificate2(cert);

            Console.WriteLine($"New Cert Thumbprint: {certificate.Thumbprint}");

            var ctor = licensingType.GetConstructors().Single();


            var rewriter = ctor.Body.GetILProcessor();

            var instToReplace = 
                ctor.Body.Instructions.Where(i => i.OpCode == OpCodes.Ldstr
                    && string.Equals((string)i.Operand, existingCert.Thumbprint, StringComparison.InvariantCultureIgnoreCase))
                .FirstOrDefault();

            if(instToReplace != null) {
                rewriter.Replace(instToReplace, Instruction.Create(OpCodes.Ldstr, certificate.Thumbprint));
            }
            else {
                Console.WriteLine("Cant find inst");
            }

            EnableSecretManagerForCustomPlan(module);

            module.Write("modified.dll");

            return 0;
        }

        private static void EnableSecretManagerForCustomPlan(ModuleDefinition module)
        {
            var customPlanType = module
                .Types
                .Where(t => t.Namespace == "Bit.Core.Models.StaticStore.Plans" && t.Name == "CustomPlan")
                .Single();

            var ctor = customPlanType
                .GetConstructors()
                .Single(c => !c.HasParameters);
            var rewriter = ctor.Body.GetILProcessor();

            var secretsManagerSetter = customPlanType.BaseType.Resolve().Methods.Single(m => m.Name == "set_SecretsManager");
            var customPlanSecretManagerFeature = module
                .Types
                .SingleOrDefault(t => t.Namespace == "Bit.Core.Models.StaticStore" && t.Name == "Plan")
                .NestedTypes.SingleOrDefault(t => t.Name == "SecretsManagerPlanFeatures");
            var customPlanSecretManagerFeatureCtor = customPlanSecretManagerFeature
                .GetConstructors()
                .Single(c => !c.HasParameters);

            //remove latest part
            rewriter.RemoveAt(rewriter.Body.Instructions.Count - 1);

            //Initialize SecretsManager with new SecretsManagerPlanFeatures
            rewriter.Emit(OpCodes.Ldarg_0);
            rewriter.Emit(OpCodes.Newobj, customPlanSecretManagerFeatureCtor);

            //SecretsManagerPlanFeatures.AllowSeatAutoscale = true
            rewriter.Emit(OpCodes.Dup);
            rewriter.Emit(OpCodes.Ldc_I4, 1);
            rewriter.Emit(OpCodes.Call, customPlanSecretManagerFeature.Methods.Single(m => m.Name == "set_AllowSeatAutoscale"));

            //SecretsManagerPlanFeatures.AllowServiceAccountsAutoscale = true
            rewriter.Emit(OpCodes.Dup);
            rewriter.Emit(OpCodes.Ldc_I4, 1);
            rewriter.Emit(OpCodes.Call, customPlanSecretManagerFeature.Methods.Single(m => m.Name == "set_AllowServiceAccountsAutoscale"));
            rewriter.Emit(OpCodes.Call, secretsManagerSetter);

            //Append return statement again
            rewriter.Emit(OpCodes.Ret);
        }
    }
}
