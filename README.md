# NAME

StrawberryBuilds - Setup an environment for building Strawberry Perl

# SYNOPSIS

You *must* have a drive letter `Z:\` available for installation of some tools we'll be using in order to build Perl.

The `setup_env.ps1` script will do some basic setups for you. You'll need to run it via PowerShell.

```PowerShell
PS C:\Users\genio> git clone https://github.com/genio/strawberry_builds.git strawbuild
PS C:\Users\genio> cd strawbuild
PS C:\Users\genio\strawbuild> .\setup_env.ps1
PS C:\Users\genio\strawbuild> cd Z:\
PS Z:\> git clone git://github.com/StrawberryPerl/Perl-Dist-Strawberry.git psd
PS Z:\> cd psd
PS Z:\psd> cpanm ExtUtils::Manifest App::cpanminus
PS Z:\psd> cpanm Data::UUID IO::Capture Portable::Dist
PS Z:\psd> perl .\Build.PL
PS Z:\psd> .\Build test
PS Z:\psd> cd devel.utils
PS Z:\psd\devel.utils> 

```

Yes, I know. I need to document more here.

# AUTHOR

Chase Whitener `<capoeirab@cpan.org>`

# COPYRIGHT & LICENSE

Copyright 2019, Chase Whitener, All Rights Reserved.

You may use, modify, and distribute this package under the
same terms as Perl itself.