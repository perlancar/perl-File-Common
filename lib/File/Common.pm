package File::Common;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use File::chdir;
use File::Find;

use Exporter qw(import);
our @EXPORT_OK = qw(list_common_files);

our %SPEC;

$SPEC{list_common_files} = {
    v => 1.1,
    summary => 'List files that are found in {all,more than one} directories',
    description => <<'_',

This routine lists files that are found in all specified directories (or, when
`min_occurrences` option is specified, files that are found in at least a
certain number of occurrences. Note that only filenames are compared, not
content/checksum. Directories are excluded.

_
    args => {
        dirs => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'dir',
            schema => ['array*', of=>'dirname*', min_len=>2],
            req => 1,
            pos => 0,
            slurpy => 1,
        },
        min_occurrence => {
            schema => 'posint*',
        },
    },
};
sub list_common_files {
    my %args = @_;

    my $dirs = $args{dirs} or die "Please specify 'dirs'";
    @$dirs >= 2 or die "Please specify at least 2 directories";
    my $min_occurrence = $args{min_occurrence};

    my @all_files; # index = dir index, elem = hash of path=>1
    for my $i (0..$#{$dirs}) {
        my $dir = $dirs->[$i];
        (-d $dir) or die "No such directory: $dir";
        local $CWD = $dir;
        my %files;
        find(
            sub {
                return unless -f;
                my $path = "$File::Find::dir/$_";
                $path =~ s!\A\./!!;
                $files{$path} = 1;
            },
            ".",
        );
        push @all_files, \%files;
    }

    my %res;
    if (defined $min_occurrence) {
        for my $i (0..$#all_files) {
            for my $f (keys %{ $all_files[$i] }) {
                $res{$f}++;
            }
        }
        return [sort grep { $res{$_} >= $min_occurrence } keys %res];
    } else {
      FILE:
        for my $f0 (keys %{ $all_files[0] }) {
            for my $i (1..$#all_files) {
                next FILE unless $all_files[$i]{$f0};
            }
            $res{$f0}++;
        }
        return [sort keys %res];
    }
}

1;
#ABSTRACT:

=head1 SYNOPSIS

 use File::Common qw(list_common_files);

 my $res = list_common_files(
     dirs => ["dir1", "dir2"],
     # min_occurrence => 2, # optional, the default if unset is to return files that exist in all dirs
 );

Given this tree:

 dir1/
   file1
   sub1/
     file2
     file3

 dir2/
   file2
   sub1/
     file3
   file3
   file4


Will return:

 ["file1", "sub1/file3"]


=head1 DESCRIPTION


=head1 SEE ALSO

L<File::Find::Duplicate>

=cut
