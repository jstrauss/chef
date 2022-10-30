$ErrorActionPreference = 'Stop'
$pkg_name="chef-infra-client"
$pkg_origin="chef"
$pkg_version=(Get-Content $PLAN_CONTEXT/../VERSION)
$pkg_description="Chef Infra Client is an agent that runs locally on every node that is under management by Chef Infra. This package is binary-only to provide Chef Infra Client executables. It does not define a service to run."
$pkg_maintainer="The Chef Maintainers <maintainers@chef.io>"
$pkg_upstream_url="https://github.com/chef/chef"
$pkg_license=@("Apache-2.0")
$pkg_filename="${pkg_name}-${pkg_version}.zip"
$pkg_bin_dirs=@(
    "bin"
    "vendor/bin"
)
$pkg_deps=@(
  "core/cacerts"
  "chef/ruby31-plus-devkit"
  "chef/chef-powershell-shim"
)

function Invoke-Begin {
    [Version]$hab_version = (hab --version).split(" ")[1].split("/")[0]
    if ($hab_version -lt [Version]"0.85.0" ) {
        Write-Warning "(╯°□°）╯︵ ┻━┻ I CAN'T WORK UNDER THESE CONDITIONS!"
        Write-Warning ":habicat: I'm being built with $hab_version. I need at least Hab 0.85.0, because I use the -IsPath option for setting/pushing paths in SetupEnvironment."
        throw "unable to build: required minimum version of Habitat not installed"
    } else {
        Write-BuildLine ":habicat: I think I have the version I need to build."
    }
}

function Invoke-SetupEnvironment {
    Push-RuntimeEnv -IsPath GEM_PATH "$pkg_prefix/vendor"

    Set-RuntimeEnv APPBUNDLER_ALLOW_RVM "true" # prevent appbundler from clearing out the carefully constructed runtime GEM_PATH
    Set-RuntimeEnv FORCE_FFI_YAJL "ext" # Always use the C-extensions because we use MRI on all the things and C is fast.
    Set-RuntimeEnv -IsPath SSL_CERT_FILE "$(Get-HabPackagePath cacerts)/ssl/cert.pem"
    Set-RuntimeEnv LANG "en_US.UTF-8"
    Set-RuntimeEnv LC_CTYPE "en_US.UTF-8"
}

# function Invoke-Download() {
#     Write-BuildLine " ** Locally creating archive of latest repository commit at ${HAB_CACHE_SRC_PATH}/${pkg_filename}"
#     # source is in this repo, so we're going to create an archive from the
#     # appropriate path within the repo and place the generated tarball in the
#     # location expected by do_unpack
#     # $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
#     # $git_path = "c:\\Program Files\\Git\\cmd"
#     # $env:Path = $git_path + ";" + [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
#     try {
#         # Push-Location (Resolve-Path "$PLAN_CONTEXT/../").Path
#         # # Write-Output "`n *** Installing Choco *** `n"
#         Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
#         choco install git -y
#         $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
#         # $env:Path = $git_path + ";" + [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
#         $full_git_path = $("C:\\Program Files\\Git\\cmd\\git.exe")
#         Write-Output "Is Git REALLY Installed? "
#         Test-Path -Path $full_git_path
#         # # Get-Command "Git"
#         Write-Output "Hab source path is : ${HAB_CACHE_SRC_PATH}`n"
#         Write-Output "Package Filename is : ${pkg_filename}"
#         Write-Output "getting Variables now`n"
#         $path = Get-Variable -Name HAB_CACHE_SRC_PATH -ValueOnly
#         $file = Get-Variable -Name pkg_filename -ValueOnly
#         Write-Output "Here's the path : $path"
#         Write-Output "Here's the file : $file"
#         $command = "c:\\Program` Files\\Git\\cmd\\git.exe archive --format=zip --output=$($path + "\" + $file) HEAD"
#         Write-Output "Here's the whole command : $command"
#         # c:\\Program` Files\\Git\\cmd\\git.exe archive --format=zip --output=$($path + "\" + $file) HEAD
#         # Invoke-Expression "& $command" -Verbose -ErrorAction Stop
#         # [System.Diagnostics.Process]::Start("c:\\Program` Files\\Git\\cmd\\git.exe archive --format=zip --output=$(${HAB_CACHE_SRC_PATH} + "\\" + ${pkg_filename}) HEAD --verbose")
#         # Write-Output "Now archiving the repo"
#         # [System.Diagnostics.Process]::Start("$full_git_path archive --format=zip --output=${HAB_CACHE_SRC_PATH}\\${pkg_filename} HEAD --verbose")
#         # Invoke-Expression -Command "$($full_git_path) archive --format=zip --output=${HAB_CACHE_SRC_PATH}\\${pkg_filename} HEAD --verbose"
#         # Write-Output "Zipping the Repo is finished"
#         # Start-Sleep -Seconds 30
#         # Write-Output " *** Finished Creating the Archive *** `n"
#         # # getting an error about the archive being in use, adding the sleep to let other handles on the file finish.
#         if (-not $?) { throw "unable to create archive of source" }
#         Write-Output "Made it to the bottom of the Try statement"
#     catch{
#         Write-BuildLine "Plan.ps1 threw an error in Invoke-Download - An error occurred:"
#         Write-BuildLine $_
#     }
#     } finally {
#         Write-Output " *** Executing Pop-Location *** "
#         Pop-Location
#         Write-Output " *** Finished Pop-Location *** "
#     }
# }
function Invoke-Download() {
    Write-BuildLine " ** Locally creating archive of latest repository commit at ${HAB_CACHE_SRC_PATH}/${pkg_filename}"
    try {
        Push-Location (Resolve-Path "$PLAN_CONTEXT/../").Path
        Write-Output "`n *** Installing Choco *** `n"
        Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        choco install git -y
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        $full_git_path = $("C:\\Program Files\\Git\\cmd\\git.exe")
        Invoke-Expression -Command "$($full_git_path) archive --format=zip --output=${HAB_CACHE_SRC_PATH}\\${pkg_filename} HEAD --verbose" -ErrorAction Stop -Verbose
    }
    catch {
        Write-BuildLine "Plan.ps1 threw an error in Invoke-Download - An error occurred:"
        Write-BuildLine $_
    }
    finally {
        Pop-Location
    }
}

function Invoke-Verify() {
    Write-BuildLine " ** Invoke Verify Top"
    Write-BuildLine " ** Skipping checksum verification on the archive we just created."
    return 0
}

function Invoke-Prepare {
    Write-BuildLine " ** Invoke Prepare Top"
    $env:GEM_HOME = "$pkg_prefix/vendor"

    try {
        Push-Location "${HAB_CACHE_SRC_PATH}/${pkg_dirname}"
        $env:Path = "C:\\ruby31\\bin;" + [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        Write-BuildLine " ** Configuring bundler for this build environment"
        bundle config --local without server docgen maintenance pry travis integration ci chefstyle
        if (-not $?) { throw "unable to configure bundler to restrict gems to be installed" }
        bundle config --local retry 5
        bundle config --local silence_root_warning 1
    } finally {
        Pop-Location
    }
}

function Invoke-Build {
    Write-BuildLine " ** Invoke-Build Top"
    try {
        Push-Location "${HAB_CACHE_SRC_PATH}/${pkg_dirname}"

        $env:_BUNDLER_WINDOWS_DLLS_COPIED = "1"

        Write-BuildLine " ** Using bundler to retrieve the Ruby dependencies"
        bundle install --jobs=3 --retry=3
        if (-not $?) { throw "unable to install gem dependencies" }
        Write-BuildLine " ** 'rake install' any gem sourced as a git reference so they'll look like regular gems."
        foreach($git_gem in (Get-ChildItem "$env:GEM_HOME/bundler/gems")) {
            try {
                Push-Location $git_gem
                Write-BuildLine " -- installing $git_gem"
                # The rest client doesn't have an 'Install' task so it bombs out when we call Rake Install for it
                # Happily, its Rakefile ultimately calls 'gem build' to build itself with. We're doing that here.
                if ($git_gem -match "rest-client"){
                    $gemspec_path = $git_gem.ToString() + "\rest-client.windows.gemspec"
                    gem build $gemspec_path
                    $gem_path = $git_gem.ToString() + "\rest-client*.gem"
                    gem install $gem_path
                }
                else {
                    rake install $git_gem --trace=stdout # this needs to NOT be 'bundle exec'd else bundler complains about dev deps not being installed
                }
                if (-not $?) { throw "unable to install $($git_gem) as a plain old gem" }
            } finally {
                Pop-Location
            }
        }
        Write-BuildLine " ** Running the chef project's 'rake install' to install the path-based gems so they look like any other installed gem."
        $install_attempt = 0
        do {
            Start-Sleep -Seconds 5
            $install_attempt++
            Write-BuildLine "Install attempt $install_attempt"
            bundle exec rake install:local --trace=stdout
        } while ((-not $?) -and ($install_attempt -lt 5))

    } finally {
        Pop-Location
    }
}

function Invoke-Install {
    try {
        Push-Location $pkg_prefix
        $env:BUNDLE_GEMFILE="${HAB_CACHE_SRC_PATH}/${pkg_dirname}/Gemfile"
        $app_bundler = @"
#! ruby
#
# This file was generated by RubyGems.
#
# The application 'appbundler' is installed as part of a gem, and
# this file is here to facilitate running it.
#

require 'rubygems'

Gem.use_gemdeps

version = ">= 0.a"

str = ARGV.first
if str
    str = str.b[/\A_(.*)_\z/, 1]
    if str and Gem::Version.correct?(str)
    version = str
    ARGV.shift
    end
end

if Gem.respond_to?(:activate_bin_path)
load Gem.activate_bin_path('appbundler', 'appbundler', version)
else
gem "appbundler", version
load Gem.bin_path("appbundler", "appbundler", version)
end
"@

        $app_bundler_bat = @"
@ECHO OFF
"%~dp0ruby.exe" "%~dpn0" %*
"@
        Set-Content -Path "C:\\Ruby31\bin\appbundler" -Value $app_bundler
        Set-Content -Path "C:\\Ruby31\bin\appbundler.bat" -Value $app_bundler_bat
        foreach($gem in ("chef-bin", "chef", "inspec-core-bin", "ohai")) {
            Write-BuildLine "** generating binstubs for $gem with precise version pins"
            appbundler.bat "${HAB_CACHE_SRC_PATH}/${pkg_dirname}" $pkg_prefix/bin $gem
            if (-not $?) { throw "Failed to create appbundled binstubs for $gem"}
        }
        Remove-StudioPathFrom -File $pkg_prefix/vendor/gems/chef-$pkg_version*/Gemfile
    } finally {
        Pop-Location
    }
}

function Invoke-After {
    # Trim the fat before packaging

    # We don't need the cache of downloaded .gem files ...
    Remove-Item $pkg_prefix/vendor/cache -Recurse -Force
    # ... or bundler's cache of git-ref'd gems
    Remove-Item $pkg_prefix/vendor/bundler -Recurse -Force

    # We don't need the gem docs.
    Remove-Item $pkg_prefix/vendor/doc -Recurse -Force
    # We don't need to ship the test suites for every gem dependency,
    # only Chef's for package verification.
    Get-ChildItem $pkg_prefix/vendor/gems -Filter "spec" -Directory -Recurse -Depth 1 `
        | Where-Object -FilterScript { $_.FullName -notlike "*chef-$pkg_version*" }   `
        | Remove-Item -Recurse -Force
    # Remove the byproducts of compiling gems with extensions
    Get-ChildItem $pkg_prefix/vendor/gems -Include @("gem_make.out", "mkmf.log", "Makefile") -File -Recurse `
        | Remove-Item -Force
}

function Remove-StudioPathFrom {
    Param(
        [Parameter(Mandatory=$true)]
        [String]
        $File
    )
    (Get-Content $File) -replace ($env:FS_ROOT -replace "\\","/"),"" | Set-Content $File
}
