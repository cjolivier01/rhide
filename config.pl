#!/usr/bin/perl
# Copyright (C) 1999-2001 by Salvador E. Tropea (SET),
# see copyrigh file for details
#
# To specify the compilation flags define the CFLAGS environment variable.
#

require "miscperl.pl";
require "conflib.pl";

GetCache();
GetVersion('');

# I never tested with an older version, you can try reducing it.
$GPMVersionNeeded='1.10';
# I never tested with an older version, you can try reducing it.
#$NCursesVersionNeeded='1.9.9';
# That's a test to see if that works:
$NCursesVersionNeeded='1.8.6';
$DJGPPVersionNeeded='2.0.2';
unlink $ErrorLog;

SeeCommandLine();

print "Configuring Turbo Vision v$Version library\n\n";
# Determine the OS
$OS=DetectOS();
# Determine C flags
$CFLAGS=FindCFLAGS();
# Determine C++ flags
$CXXFLAGS=FindCXXFLAGS();
# Test for a working gcc
$GCC=CheckGCC();
# Check if gcc can compile C++
$GXX=CheckGXX();
# Which architecture are we using?
DetectCPU();
# Some platforms aren't easy to detect until we can compile.
DetectOS2();
# The prefix can be better determined if we know all the rest
# about the environment
LookForPrefix();
# Only gnu make have the command line and commands we use.
LookForGNUMake();
# Same for ar, it could be `gar'
LookForGNUar();
# Is the right djgpp?
if ($OS eq 'DOS')
  {
   LookForDJGPP($DJGPPVersionNeeded);
  }

if ($OS eq 'UNIX')
  {
   LookForGPM($GPMVersionNeeded);
   LookForNCurses($NCursesVersionNeeded);
   LookForKeysyms();
   #LookForOutB();
  }
LookForIntlSupport();
LookForEndianess();

print "\n";
GenerateMakefile();
#
# For the examples
#
$here=`pwd`;
chop($here);
if (!$here && ($OS ne 'UNIX'))
  {# command.com, cmd.exe, etc. have it.
   $here=`cd`;
   chop($here);
  }
# Path for the includes
$MakeDefsRHIDE[1]='TVSRC=../../include '.$here.'/include '.@conf{'prefix'}.'/include/rhtvision';
# Libraries needed
$MakeDefsRHIDE[2]='RHIDE_OS_LIBS=';
 # RHIDE doesn't know about anything different than DJGPP and Linux so -lstdc++ must
 # be added for things like FreeBSD or SunOS.
$MakeDefsRHIDE[2].=substr($stdcxx,2) unless (($OS eq 'DOS') || ($OSf eq 'Linux'));
$MakeDefsRHIDE[2].=' intl' if (($OS eq 'DOS') || ($OS eq 'Win32')) && (@conf{'intl'} eq 'yes');
$MakeDefsRHIDE[2].=' iconv' if (@conf{'iconv'} eq 'yes');
$MakeDefsRHIDE[2].=' '.$conf{'NameCurses'}.' m' if ($OS eq 'UNIX');
$MakeDefsRHIDE[2].=' gpm' if @conf{'HAVE_GPM'} eq 'yes';
$MakeDefsRHIDE[4]='RHIDE_AR='.$conf{'GNU_AR'};
if ($OS eq 'UNIX')
  {
   $MakeDefsRHIDE[0]='RHIDE_STDINC=/usr/include /usr/local/include /usr/include/g++ /usr/local/include/g++ /usr/lib/gcc-lib /usr/local/lib/gcc-lib';
   $MakeDefsRHIDE[3]='TVOBJ='.$here.'/linux '.@conf{'prefix'}.'/lib ../../linux';
   ModifyMakefiles('linux/Makefile');
   CreateRHIDEenvs('linux/rhide.env','examples/rhide.env','compat/rhide.env');
  }
elsif ($OS eq 'DOS')
  {
   $MakeDefsRHIDE[0]='RHIDE_STDINC=$(DJDIR)/include $(DJDIR)/lang/cxx $(DJDIR)/lib/gcc-lib';
   $MakeDefsRHIDE[3]='TVOBJ='.$here.'/djgpp '.@conf{'prefix'}.'/lib ../../djgpp';
   ModifyMakefiles('djgpp/makefile');
   CreateRHIDEenvs('djgpp/rhide.env','examples/rhide.env','compat/rhide.env');
  }
elsif ($OS eq 'Win32')
  {
   $MakeDefsRHIDE[3]='TVOBJ='.$here.'/win32 '.@conf{'prefix'}.'/lib ../../win32';
   $ExtraModifyMakefiles{'vpath_src'}="../classes/win32 ../stream ../names ../classes .. ../djgpp\nvpath %.h ../djgpp";
   `cp djgpp/makefile win32/Makefile`;
   ModifyMakefiles('win32/Makefile');
   CreateRHIDEenvs('examples/rhide.env');
   # Repeated later for other targets
  }
CreateConfigH();

# Help MinGW target
if ($OS ne 'Win32')
  {
   $MakeDefsRHIDE[0]='';
   $MakeDefsRHIDE[2]='RHIDE_OS_LIBS='.substr($stdcxx,2);
   $MakeDefsRHIDE[3]='TVOBJ='.$here.'/win32 '.@conf{'prefix'}.'/lib ../../win32';
   $ExtraModifyMakefiles{'vpath_src'}="../classes/win32 ../stream ../names ../classes .. ../djgpp\nvpath %.h ../djgpp";
   `cp djgpp/makefile win32/Makefile`;
   ModifyMakefiles('win32/Makefile');
  }
# Help BC++ target
`perl confignt.pl`;

# UNIX dynamic library
if ($OS eq 'UNIX')
  {
   $ReplaceTags{'LIB_GPM_SWITCH'}=@conf{'HAVE_GPM'} eq 'yes' ? '-lgpm' : '';
   $ReplaceTags{'LIB_STDCXX_SWITCH'}=$stdcxx;
   $ReplaceTags{'make'}=$conf{'GNU_Make'};
   ReplaceText('linuxso/makemak.in','linuxso/makemak.pl');
   chmod(0755,'linuxso/makemak.pl');
  }
#
# Adjust .mak files
#
print "Makefiles for examples.\n";
chdir('examples');
`perl patchenv.pl`;
chdir('..');

print "\nSuccesful configuration!\n\n";

GiveAdvice();
CreateCache();
unlink $ErrorLog;
unlink 'test.exe';

sub SeeCommandLine
{
 my $i;

 foreach $i (@ARGV)
   {
    if ($i eq '--help')
      {
       ShowHelp();
       die "\n";
      }
    elsif ($i=~'--prefix=(.*)')
      {
       $conf{'prefix'}=$1;
      }
    elsif ($i eq '--no-intl')
      {
       $conf{'no-intl'}='yes';
      }
    elsif ($i=~'--cflags=(.*)')
      {
       @conf{'CFLAGS'}=$1;
      }
    elsif ($i=~'--cxxflags=(.*)')
      {
       @conf{'CXXFLAGS'}=$1;
      }
    elsif ($i eq '--fhs')
      {
       $conf{'fhs'}='yes';
      }
    else
      {
       ShowHelp();
       die "Unknown option: $i\n";
      }
   }
}

sub ShowHelp
{
 print "Available options:\n\n";
 print "--help         : displays this text.\n";
 print "--prefix=path  : defines the base directory for installation.\n";
 print "--no-intl      : don't use international support.\n";
 print "--fhs          : force the FHS layout under UNIX.\n";
 print "--cflags=val   : normal C flags [default is env. CFLAGS].\n";
 print "--cxxflags=val : normal C++ flags [default is env. CXXFLAGS].\n";
}

sub GiveAdvice
{
 if ((@conf{'intl'} eq 'no') && (@conf{'no-intl'} ne 'yes'))
   {
    print "\n";
    print "* The international support was disabled because gettext library could not\n";
    print "  be detected.\n";
    if ($OSf eq 'Linux')
      {
       print "  Starting with glibc 2.0 this is included in libc, perhaps your system\n";
       print "  just lacks the propper header file.\n";
      }
    elsif ($OS eq 'DOS')
      {
       print "  Install the gtxtNNNb.zip package from the v2gnu directory of djgpp's\n";
       print "  distribution. Read the readme file for more information.\n";
      }
    elsif ($Compf eq 'MinGW')
      {
       print "  That's normal for MinGW.\n";
      }
    elsif ($Compf eq 'Cygwin')
      {
       print "  Install gettext library.\n";
      }
   }
 if ((@conf{'HAVE_GPM'} eq 'no') && ($OSf eq 'Linux'))
   {
    print "\n";
    print "* No mouse support for console! please install the libgpm package needed\n";
    print "  for development. (i.e. libgpmg1-dev_1.13-5.deb).\n";
   }
 if (@conf{'GNU_Make'} ne 'make')
   {
    print "\n";
    print "* Please use $conf{'GNU_Make'} instead of make command.\n";
   }
}

sub LookForEndianess
{

 my $test;

 print 'Checking endianess: ';

 if (@conf{'TV_BIG_ENDIAN'} eq 'yes')
   {
    print "big endian (cached)\n";
    return;
   }
 if (@conf{'TV_BIG_ENDIAN'} eq 'no')
   {
    print "little endian (cached)\n";
    return;
   }
 $test='
#include <stdio.h>
int main(void)
{
 int a=1;
 char *s=(char *)&a;
 printf("%s\n",s[0]==1 ? "little" : "big");
 return 0;
}
';
 $test=RunGCCTest($GCC,'c',$test,'');
 chop($test);
 $conf{'TV_BIG_ENDIAN'}=($test eq "big") ? 'yes' : 'no';
 print "$test endian\n";
}

sub LookForIntlSupport
{
 my $vNeed=$_[0];
 my ($test,$a,$djdir,$intllib,$intltest);

 print 'Checking for international support: ';
 if (@conf{'no-intl'} eq 'yes')
   {
    print "disabled by user request.\n";
    $conf{'intl'}='no';
    $conf{'iconv'}='no';
    #`cp include/tv/nointl.h include/tv/intl.h`;
    return;
   }
 if (@conf{'intl'} eq 'yes')
   {
    print "yes (cached)\n";
    return;
   }
 if (@conf{'intl'} eq 'no')
   {
    print "no (cached)\n";
    return;
   }
 if ($OS eq 'DOS')
   { # gettext 0.10.32 port have a bug in the headers, correct it
    $djdir=@ENV{'DJDIR'};
    $a=cat("$djdir/include/libintl.h");
    if (length($a) && $a=~/\@INCLUDE_LOCALE_H@/)
      {
       $a=~s/\@INCLUDE_LOCALE_H\@//;
       replace("$djdir/include/libintl.h",$a);
      }
   }
 $intltest='
#include <stdio.h>
#define FORCE_INTL_SUPPORT
#include <tv/intl.h>
int main(void)
{
 printf("%s\n",_("OK"));
 return 0;
}
';
 $intllib=(($OS eq 'DOS') || ($OS eq 'Win32')) ? '-lintl' : '';
 $test=RunGCCTest($GCC,'c',$intltest,'-Iinclude/ '.$intllib);
 if ($test ne "OK\n")
   {
    print "no, additional check required.\n";
    print "Checking for extra libs for international support: ";
    $test=RunGCCTest($GCC,'c',$intltest,'-Iinclude/ '.$intllib.' -liconv');
    if ($test ne "OK\n")
      {
       print "none found\n";
       print "International support absent or non-working\n";
       $conf{'intl'}='no';
       $conf{'iconv'}='no';
      }
    else
      {
       print "-liconv, OK\n";
       $conf{'intl'}='yes';
       $conf{'iconv'}='yes';
      }
   }
 else
   {
    print "yes OK\n";
    $conf{'intl'}='yes';
    $conf{'iconv'}='no';
   }
}

sub LookForKeysyms
{
 my $test;

 print 'Looking for X keysyms definitions: ';
 if (@conf{'HAVE_KEYSYMS'})
   {
    print "@conf{'HAVE_KEYSYMS'} (cached)\n";
    return;
   }
 $test='
#include <stdio.h>
#include <X11/keysym.h>
int main(void)
{
 if (XK_Return!=0)
    printf("OK\n");
 return 0;
}
';
 $test=RunGCCTest($GCC,'c',$test,'');
 if ($test eq "OK\n")
   {
    $conf{'HAVE_KEYSYMS'}='yes';
    print " yes OK\n";
   }
 else
   {
    $conf{'HAVE_KEYSYMS'}='no';
    print " no, disabling enhanced support for Eterm 0.8.10+\n";
   }
}

#
# GlibC 2.1.3 defines it by itself, lamentably doesn't have any protection
# mechanism to avoid collisions with the kernel headers, too bad.
#
sub LookForOutB
{
 my $test;

 print 'Looking for outb definition in sys/io.h: ';
 if (@conf{'HAVE_OUTB_IN_SYS'})
   {
    print "@conf{'HAVE_OUTB_IN_SYS'} (cached)\n";
    return;
   }
 $test='
#include <stdio.h>
#include <sys/io.h>
#ifdef __i386__
static volatile void Test(void) { outb(10,0x300); }
#endif
int main(void)
{
 printf("OK\n");
 return 0;
}
';
 $test=RunGCCTest($GCC,'c',$test,'');
 $conf{'HAVE_OUTB_IN_SYS'}=($test eq "OK\n") ? 'yes' : 'no';
 print "@conf{'HAVE_OUTB_IN_SYS'}\n";
 #print ">$test<\n";
}

sub LookForGPM
{
 my $vNeed=$_[0],$test;

 print 'Looking for gpm library: ';
 if (@conf{'gpm'})
   {
    print "@conf{'gpm'} (cached) OK\n";
    return;
   }
 $test='
#include <stdio.h>
#include <gpm.h>
int main(void)
{
 int version;
 printf("%s",Gpm_GetLibVersion(&version));
 return 0;
}
';
 $test=RunGCCTest($GCC,'c',$test,'-lgpm');
 if (!length($test))
   {
    #print "\nError: gpm library not found, please install gpm $vNeed or newer\n";
    #print "Look in $ErrorLog for potential compile errors of the test\n";
    #CreateCache();
    #die "Missing library\n";
    $conf{'HAVE_GPM'}='no';
    print " no, disabling mouse support\n";
    return;
   }
 if (!CompareVersion($test,$vNeed))
   {
    #print "$test, too old\n";
    #print "Please upgrade your gpm library to version $vNeed or newer.\n";
    #print "You can try with $test forcing the configure scripts.\n";
    #CreateCache();
    #die "Old library\n";
    $conf{'HAVE_GPM'}='no';
    print " too old, disabling mouse support\n";
    return;
   }
 $conf{'gpm'}=$test;
 $conf{'HAVE_GPM'}='yes';
 print "$test OK\n";
}

sub LookForNCurses
{
 my ($vNeed)=@_;
 my ($result,$test);

 print 'Looking for ncurses library: ';
 if (@conf{'ncurses'})
   {
    print "@conf{'ncurses'} (cached) OK\n";
    return;
   }
 # Assume it is -lncurses
 $conf{'NameCurses'}='ncurses';
 $test='
#include <stdio.h>
#include <ncurses.h>
void dummy() {initscr();}
int main(void)
{
 printf(NCURSES_VERSION);
 return 0;
}
';
 $result=RunGCCTest($GCC,'c',$test,'-lncurses');
 if (!length($result))
   {# Try again with -lcurses, In Solaris ncurses is installed this way
    $result=RunGCCTest($GCC,'c',$test,'-lcurses');
    if (!length($result))
      {
       print "\nError: ncurses library not found, please install ncurses $vNeed or newer\n";
       print "Look in $ErrorLog for potential compile errors of the test\n";
       CreateCache();
       die "Missing library\n";
      }
    $conf{'NameCurses'}='curses';
   }
 if (!CompareVersion($result,$vNeed))
   {
    print "$result, too old\n";
    print "Please upgrade your ncurses library to version $vNeed or newer.\n";
    print "You can try with $result forcing the configure scripts.\n";
    CreateCache();
    die "Old library\n";
   }
 print "$result OK\n";
 @conf{'ncurses'}=$result;

 print 'Checking if ncurses have define_key: ';
 $test='
#include <stdio.h>
#include <ncurses.h>
void dummy(void) { define_key("\x1B[8~",KEY_F(59)); /* End */ }
int main(void)
{
 printf("Ok\n");
 return 0;
}
';
 $result=RunGCCTest($GCC,'c',$test,'-l'.$conf{'NameCurses'});
 chop($result);
 if ($result eq 'Ok')
   {
    print "yes\n";
    $conf{'HAVE_DEFINE_KEY'}=1;
   }
 else
   {
    print "no\n";
    $conf{'HAVE_DEFINE_KEY'}=0;
   }
}

sub GenerateMakefile
{
 my ($text,$rep,$makeDir);

 print "Generating Makefile\n";
 $text=cat('Makefile.in');
 if (!$text)
   {
    CreateCache();
    die "Can't find Makefile.in!!\n";
   }
 $rep='static-lib';
 $rep.=' dynamic-lib' if ($OS eq 'UNIX');
 $text=~s/\@targets\@/$rep/g;
 $text=~s/\@OS\@/$OS/g;
 $text=~s/\@prefix\@/@conf{'prefix'}/g;

 $makeDir='linux' if ($OS eq 'UNIX');
 $makeDir='djgpp' if ($OS eq 'DOS');
 $makeDir='win32' if ($OS eq 'Win32');
 # Write target rules:
 #$rep="static-lib: $makeDir/librhtv.a\n$makeDir/librhtv.a:\n\t\$(MAKE) -C ".$makeDir;
 $rep="static-lib:\n\t\$(MAKE) -C ".$makeDir;
 $text=~s/\@target1_rule\@/$rep/g;
 if ($OS eq 'UNIX')
   {
    #$rep="linuxso/librhtv.so.$Version";
    #$rep="dynamic-lib: $rep\n$rep:\n\tcd linuxso; ./makemak.pl --no-inst-message";
    $rep="dynamic-lib:\n\tcd linuxso; ./makemak.pl --no-inst-message";
    $text=~s/\@target2_rule\@/$rep/g;
   }
 else
   {
    $text=~s/\@target2_rule\@//g;
   }

 # Write install stuff
 # What versions of the library we will install
 $rep= 'install-static ';
 $rep.='install-dynamic' if ($OS eq 'UNIX');
 $text=~s/\@installers\@/$rep/g;

 # Headers
 $rep= "install -d -m 0755 \$(prefix)/include/rhtvision\n";
 $rep.="\trm -f \$(prefix)/include/rhtvision/*.h\n";
 $rep.="\tinstall -m 0644 include/*.h \$(prefix)/include/rhtvision\n";
 $rep.="\tinstall -d -m 0755 \$(prefix)/include/rhtvision/tv\n";
 $rep.="\tinstall -m 0644 include/tv/*.h \$(prefix)/include/rhtvision/tv\n";
 $rep.="\tinstall -d -m 0755 \$(prefix)/include/rhtvision/cl\n";
 $rep.="\tinstall -m 0644 include/cl/*.h \$(prefix)/include/rhtvision/cl\n";
 $text=~s/\@install_headers\@/$rep/g;
 
 # Static library
 $rep ="install-static: static-lib\n";
 $rep.="\tinstall -d -m 0755 \$(libdir)\n";
 $rep.="\tinstall -m 0644 $makeDir/librhtv.a \$(libdir)\n";
 $text=~s/\@install1_rule\@/$rep/g;

 $rep='';
 if ($OS eq 'UNIX')
   {# Dynamic library
    $rep= "install-dynamic: dynamic-lib\n";
    $rep.="\trm -f \$(libdir)/librhtv.so\n";
    $rep.="\trm -f \$(libdir)/librhtv.so.1\n";
    $rep.="\trm -f \$(libdir)/librhtv.so.$Version\n";
    $rep.="\tcd \$(libdir); ln -s librhtv.so.$Version librhtv.so\n";
    # Not needed if the soname changes which each version (at least Ivan says that)
    #$rep.="\tcd \$(libdir); ln -s librhtv.so.$Version librhtv.so.1\n";
    $rep.="\tinstall -m 0644 linuxso/librhtv.so.$Version \$(libdir)\n";
    $rep.="\tstrip --strip-debug \$(libdir)/librhtv.so.$Version\n";
    $rep.="\t-ldconfig\n";
   }
 $text=~s/\@install2_rule\@/$rep/g;

 $rep= "clean:\n";
 $rep.="\trm -f linuxso/librhtv.so*\n";
 $rep.="\trm -f linuxso/obj/*.o\n";
 $rep.="\trm -f linux/librhtv.a\n";
 $rep.="\trm -f linux/obj/*.o\n";
 $rep.="\trm -f compat/obj/*.o\n";
 $rep.="\trm -f djgpp/obj/*.o\n";
 $rep.="\texamples/clean\n";
 $text=~s/\@clean\@/$rep/g;

 replace('Makefile',$text);
}

sub CreateConfigH
{
 my $text="/* Generated automatically by the configure script */",$old;

 print "Generating configuration header\n";

 $text.=ConfigIncDef('HAVE_DEFINE_KEY','ncurses 4.2 or better have define_key (In Linux)');
 $text.=ConfigIncDefYes('HAVE_KEYSYMS','The X11 keysyms are there');
 $conf{'HAVE_INTL_SUPPORT'}=@conf{'intl'};
 $text.=ConfigIncDefYes('HAVE_INTL_SUPPORT','International support with gettext');
 $text.=ConfigIncDefYes('HAVE_GPM','GPM mouse support');
 $text.=ConfigIncDefYes('HAVE_OUTB_IN_SYS','out/in functions defined by glibc');
 $text.=ConfigIncDefYes('TV_BIG_ENDIAN','Byte order for this machine');
 $text.="\n\n";
 $text.="#define TVOS_$OS\n";
 $text.="#define TVOSf_$OSf\n";
 $text.="#define TVCPU_$CPU\n";
 $text.="#define TVComp_$Comp\n";
 $text.="#define TVCompf_$Compf\n";

 $old=cat('include/tv/configtv.h');
 replace('include/tv/configtv.h',$text) unless $text eq $old;
}
