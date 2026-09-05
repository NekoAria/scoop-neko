#Requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $OutputPath
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

if ($PSVersionTable.PSEdition -ne 'Desktop') {
    throw 'The launcher must be built with Windows PowerShell 5.1.'
}

$outputDirectory = Split-Path -Parent $OutputPath
if ([string]::IsNullOrWhiteSpace($outputDirectory)) {
    throw 'OutputPath must include a directory.'
}

[System.IO.Directory]::CreateDirectory($outputDirectory) | Out-Null
Remove-Item -LiteralPath $OutputPath -Force -ErrorAction SilentlyContinue

$sourceCode = @'
using System;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;

namespace CherryStudioUnpacked
{
    internal static class Program
    {
        private const string AppFileName = "Cherry Studio.exe";
        private const string LauncherFileName = "cherry-studio-unpacked.exe";
        private const uint ErrorIcon = 0x00000010;

        [DllImport("user32.dll", CharSet = CharSet.Unicode)]
        private static extern int MessageBoxW(IntPtr window, string text, string caption, uint type);

        [STAThread]
        private static int Main(string[] args)
        {
            string rootDirectory = NormalizeDirectory(AppDomain.CurrentDomain.BaseDirectory);
            string appPath = Path.Combine(rootDirectory, "app", AppFileName);

            try
            {
                if (!File.Exists(appPath))
                {
                    throw new FileNotFoundException("The Cherry Studio executable was not found.", appPath);
                }

                ProcessStartInfo startInfo = new ProcessStartInfo
                {
                    FileName = appPath,
                    WorkingDirectory = Path.GetDirectoryName(appPath),
                    UseShellExecute = false,
                    Arguments = BuildArguments(args)
                };
                startInfo.EnvironmentVariables["PORTABLE_EXECUTABLE_DIR"] = rootDirectory;
                startInfo.EnvironmentVariables["PORTABLE_EXECUTABLE_FILE"] = Path.Combine(rootDirectory, LauncherFileName);
                startInfo.EnvironmentVariables["PORTABLE_EXECUTABLE_APP_FILENAME"] = AppFileName;

                Process process = Process.Start(startInfo);
                if (process == null)
                {
                    throw new InvalidOperationException("Windows did not create the Cherry Studio process.");
                }

                process.Dispose();
                return 0;
            }
            catch (Exception exception)
            {
                MessageBoxW(
                    IntPtr.Zero,
                    "Unable to start Cherry Studio.\n\n" + exception.Message,
                    "Cherry Studio Unpacked",
                    ErrorIcon);
                return 1;
            }
        }

        private static string NormalizeDirectory(string directory)
        {
            string fullPath = Path.GetFullPath(directory);
            string root = Path.GetPathRoot(fullPath);
            if (!string.Equals(fullPath, root, StringComparison.OrdinalIgnoreCase))
            {
                fullPath = fullPath.TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
            }
            return fullPath;
        }

        private static string BuildArguments(string[] args)
        {
            StringBuilder commandLine = new StringBuilder();
            foreach (string argument in args)
            {
                if (commandLine.Length > 0)
                {
                    commandLine.Append(' ');
                }
                commandLine.Append(QuoteArgument(argument));
            }
            return commandLine.ToString();
        }

        // .NET Framework accepts a single argument string, so preserve argument
        // boundaries using Windows command-line quoting rules.
        private static string QuoteArgument(string argument)
        {
            bool requiresQuotes = argument.Length == 0;
            foreach (char character in argument)
            {
                if (char.IsWhiteSpace(character) || character == '"')
                {
                    requiresQuotes = true;
                    break;
                }
            }

            if (!requiresQuotes)
            {
                return argument;
            }

            StringBuilder quotedArgument = new StringBuilder();
            quotedArgument.Append('"');
            int pendingBackslashes = 0;

            foreach (char character in argument)
            {
                if (character == '\\')
                {
                    pendingBackslashes++;
                    continue;
                }

                if (character == '"')
                {
                    quotedArgument.Append('\\', pendingBackslashes * 2 + 1);
                    quotedArgument.Append('"');
                }
                else
                {
                    quotedArgument.Append('\\', pendingBackslashes);
                    quotedArgument.Append(character);
                }
                pendingBackslashes = 0;
            }

            quotedArgument.Append('\\', pendingBackslashes * 2);
            quotedArgument.Append('"');
            return quotedArgument.ToString();
        }
    }
}
'@

$compilerParameters = @{
    TypeDefinition = $sourceCode
    Language       = 'CSharp'
    OutputAssembly = $OutputPath
    OutputType     = 'WindowsApplication'
}
Add-Type @compilerParameters

if (!(Test-Path -LiteralPath $OutputPath -PathType Leaf)) {
    throw "Launcher compilation did not produce '$OutputPath'."
}
