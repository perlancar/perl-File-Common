#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use File::Common qw(list_common_files);
use File::Create::Layout qw(create_files_using_layout);
use File::Temp qw(tempdir);

my $DEBUG = $ENV{DEBUG};
my $tempdir = tempdir(CLEANUP => !$DEBUG);
note "tempdir=$tempdir";

my $layout = <<'_';
dir1/
  a
  b
  d
  sub1/
    g
    h
    j
  sub2/
    m
    n

dir2/
  a
  b
  c
  e
  sub1/
    g
    h
    i
    l
  sub2/
    m
    o

dir3/
  a
  c
  f
  sub1/
    g
    i
    m
  sub2
_
my $res = create_files_using_layout(layout=>$layout, prefix=>$tempdir);
$res->[0] == 200 or die "Can't create files: $res->[0] - $res->[1]";

subtest "basics" => sub {
    is_deeply(
        list_common_files(
            dirs => ["$tempdir/dir1", "$tempdir/dir2", "$tempdir/dir3"]),
        [qw(a sub1/g)],
    );
};

subtest "opt: min_occurrence" => sub {
    is_deeply(
        list_common_files(
            dirs => ["$tempdir/dir1", "$tempdir/dir2", "$tempdir/dir3"],
            min_occurrence => 2),
        [qw(a b c sub1/g sub1/h sub1/i sub2/m)],
    );
};

done_testing;
