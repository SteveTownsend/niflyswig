using Microsoft.VisualStudio.TestTools.UnitTesting;
using System;
using System.IO;
using System.Reflection;
using nifly;

namespace niflytest
{
    [TestClass]
    public class FileRoundTrip
    {
        private static string dataFileLocation;
        private static TestContext myContext;

        private bool FilesAreEqual(string f1, string f2)
        {
            // get file length and make sure lengths are identical
            long length = new FileInfo(f1).Length;
            if (length != new FileInfo(f2).Length)
                return false;

            // open both for reading
            using (FileStream stream1 = File.OpenRead(f1))
            using (FileStream stream2 = File.OpenRead(f2))
            {
                // compare content for equality
                int b1, b2;
                while (length-- > 0)
                {
                    b1 = stream1.ReadByte();
                    b2 = stream2.ReadByte();
                    if (b1 != b2)
                        return false;
                }
            }

            return true;
        }

        [AssemblyInitialize]
        public static void AssemblyInit(TestContext context)
        {
            // Executes once before the test run. (Optional)
            string pathAssembly = Assembly.GetExecutingAssembly().Location;
            string folderAssembly = Path.GetDirectoryName(pathAssembly);
            if (folderAssembly.EndsWith("\\") == false)
                folderAssembly += "\\";
            folderAssembly += "..\\..\\..\\data";
            dataFileLocation = System.IO.Path.GetFullPath(folderAssembly);
        }
        [ClassInitialize]
        public static void TestFixtureSetup(TestContext context)
        {
            // Executes once for the test class. (Optional)
            myContext = context;
        }
        [TestInitialize]
        public void Setup()
        {
            // Runs before each test. (Optional)
        }
        [AssemblyCleanup]
        public static void AssemblyCleanup()
        {
            // Executes once after the test run. (Optional)
        }
        [ClassCleanup]
        public static void TestFixtureTearDown()
        {
            // Runs once after all tests in this class are executed. (Optional)
            // Not guaranteed that it executes instantly after all tests from the class.
        }
        [TestCleanup]
        public void TearDown()
        {
            // Runs after each test. (Optional)
        }
        // Mark that this is a unit test method. (Required)
        [TestMethod]
        public void LoadSaveIdentical()
        {
            // read each test NIF and make sure writing it back results in identical data
            nifly.NifLoadOptions loadOptions = new NifLoadOptions();
            loadOptions.isTerrain = false;

            nifly.NifSaveOptions saveOptions = new NifSaveOptions();
            saveOptions.optimize = false;
            saveOptions.sortBlocks = false;

            int failed = 0;
            int matched = 0;
            foreach (string fileName in Directory.EnumerateFiles(dataFileLocation, "*.nif"))
            {
                var nifFile = new nifly.NifFile(true);
                int loadResult = nifFile.Load(fileName, loadOptions);
                int saveResult = nifFile.Save(fileName + ".new", saveOptions);
                if (FilesAreEqual(fileName, fileName + ".new"))
                {
                    myContext.WriteLine(String.Format("Roundtrip mismatch {0}", fileName));
                    ++failed;
                }
                else
                {
                    ++matched;
                }
            }
            myContext.WriteLine(String.Format("NIF Files {0} matched, {1} failed", failed, matched));
        }

    }
}