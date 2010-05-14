use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'MooseX::DFV',
    VERSION_FROM      => 'lib/MooseX/DFV.pm', # finds $VERSION
    PREREQ_PM         => {
        Moose => 0.60,
        'Data::FormValidator' => 4.66, 
        'MooseX::Types' => 0.20,
        'Test::More' => 0,
        'String::CamelCase' => 0.02,
        'Perl6::Junction' => 1.40000,
    }, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/MooseX/DFV.pm', # retrieve abstract from module
       AUTHOR         => 'Rob Edwards <robin.ge@gmail.com>') : ()),
);
