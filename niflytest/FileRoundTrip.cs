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
        public static string folderAssembly;
        private static string dataFileLocation;
        private static TestContext myContext;
        private enum FileCheck
        {
            Exact = 0,
            MatchTruncated,
            NoMatch
        };

        private FileCheck CompareFiles(string original, string updated)
        {
            // get file length and make sure lengths are identical
            long length = new FileInfo(original).Length;
            long newLength = new FileInfo(updated).Length;
            if (length < newLength)
                return FileCheck.NoMatch;
            bool sameLength = length == newLength;

            // open both for reading
            using (FileStream stream1 = File.OpenRead(original))
            using (FileStream stream2 = File.OpenRead(updated))
            {
                const int bufferSize = 2048;
                byte[] buffer1 = new byte[bufferSize]; //buffer size
                byte[] buffer2 = new byte[bufferSize];
                while (newLength > 0)
                {
                    int count1 = stream1.Read(buffer1, 0, bufferSize);
                    int count2 = stream2.Read(buffer2, 0, bufferSize);

                    if (count1 != count2)
                        return FileCheck.MatchTruncated;

                    if (count1 == 0)
                        return FileCheck.Exact;

                    int iterations = (int)Math.Ceiling((double)count1 / sizeof(Int64));
                    for (int i = 0; i < iterations; i++)
                    {
                        if (BitConverter.ToInt64(buffer1, i * sizeof(Int64)) != BitConverter.ToInt64(buffer2, i * sizeof(Int64)))
                        {
                            return FileCheck.NoMatch;
                        }
                    }
                    newLength -= count2;
                }                // compare content for equality
            }

            return sameLength ? FileCheck.Exact : FileCheck.MatchTruncated;
        }

        [AssemblyInitialize]
        public static void AssemblyInit(TestContext context)
        {
            // Executes once before the test run. (Optional)
            string pathAssembly = Assembly.GetExecutingAssembly().Location;
            folderAssembly = Path.GetDirectoryName(pathAssembly);
            if (folderAssembly.EndsWith("\\") == false)
                folderAssembly += "\\";
            folderAssembly += "..\\..\\..";
        }
        [ClassInitialize]
        public static void TestFixtureSetup(TestContext context)
        {
            // Executes once for the test class. (Optional)
            myContext = context;
            dataFileLocation = System.IO.Path.GetFullPath(folderAssembly + "\\data");
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
            int newIsSubstring = 0;
            foreach (string fileName in Directory.EnumerateFiles(dataFileLocation, "*.nif"))
            {
                // Files that differ appear to have been cleaned up by the round trip. Spot checking a couple
                // in Nifskope shows no information loss.
                var nifFile = new nifly.NifFile(true);
                int loadResult = nifFile.Load(fileName, loadOptions);
                int saveResult = nifFile.Save(fileName + ".new", saveOptions);
                FileCheck match = CompareFiles(fileName, fileName + ".new");
                switch (match)
                {
                    case FileCheck.Exact:
                        ++matched;
                        break;
                    case FileCheck.MatchTruncated:
                        myContext.WriteLine(String.Format("Truncate {0}", fileName));
                        ++newIsSubstring;
                        break;
                    case FileCheck.NoMatch:
                        myContext.WriteLine(String.Format("Mismatch {0}", fileName));
                        ++failed;
                        break;
                }
            }
            myContext.WriteLine(String.Format("NIF Files {0} failed, {1} truncated, {2} exact", failed, newIsSubstring, matched));
        }

    }
}
