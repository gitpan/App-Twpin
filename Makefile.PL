
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
                       'ABSTRACT' => 'Just Another Command Line Twitter Client',
                       'EXE_FILES' => [
                                        'bin/twpin'
                                      ],
                       'VERSION' => '0.002',
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



