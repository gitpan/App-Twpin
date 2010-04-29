
use strict;
use warnings;



use ExtUtils::MakeMaker 6.11;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'App::Twpin',
                       'DISTNAME' => 'App-Twpin',
                       'AUTHOR' => 'woosley.xu',
                       'ABSTRACT' => 'command line twitter tool',
                       'EXE_FILES' => [
                                        'bin/twpin'
                                      ],
                       'VERSION' => '0.001',
                       'LICENSE' => 'perl',
                       'PREREQ_PM' => {
                                        'ExtUtils::MakeMaker' => '6.11',
                                        'Tie::File' => '0',
                                        'Net::Twitter' => '3.12000'
                                      }
                     );


delete $WriteMakefileArgs{LICENSE}
  unless eval { ExtUtils::MakeMaker->VERSION(6.31) };

WriteMakefile(%WriteMakefileArgs);



