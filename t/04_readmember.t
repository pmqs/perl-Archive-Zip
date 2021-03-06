#!/usr/bin/perl

# See https://github.com/redhotpenguin/perl-Archive-Zip/blob/master/t/README.md
# for a short documentation on the Archive::Zip test infrastructure.

use strict;

BEGIN { $^W = 1; }

use Test::More tests => 10;

use Archive::Zip qw();
use Archive::Zip::MemberRead qw();

use lib 't';
use common;

# Test Archive::Zip::MemberRead

use constant FILENAME => testPath('member_read.zip');

my ($zip, $member, $fh, @data);
$zip = new Archive::Zip;
isa_ok($zip, 'Archive::Zip');
@data = ('Line 1', 'Line 2', '', 'Line 3', 'Line 4');

$zip->addString(join("\n", @data), 'string.txt');
$zip->writeToFileNamed(FILENAME);

$member = $zip->memberNamed('string.txt');
$fh     = $member->readFileHandle();
ok($fh);

my ($line, $not_ok, $ret, $buffer);
while (defined($line = $fh->getline())) {
    $not_ok = 1 if ($line ne $data[$fh->input_line_number() - 1]);
}
SKIP: {
    if ($^O eq 'MSWin32') {
        skip("Ignoring failing test on Win32", 1);
    }
    ok(!$not_ok);
}

my $member_read = Archive::Zip::MemberRead->new($zip, 'string.txt');
$line = $member_read->getline({'preserve_line_ending' => 1});
is($line, "Line 1\n", 'Preserve line ending');
$line = $member_read->getline({'preserve_line_ending' => 0});
is($line, "Line 2", 'Do not preserve line ending');

$fh->rewind();
$ret = $fh->read($buffer, length($data[0]));
ok($ret == length($data[0]));
ok($buffer eq $data[0]);
$fh->close();

#
# Different usages
#
$fh = new Archive::Zip::MemberRead($zip, 'string.txt');
ok($fh);

$fh = new Archive::Zip::MemberRead($zip, $zip->memberNamed('string.txt'));
ok($fh);

$fh = new Archive::Zip::MemberRead($zip->memberNamed('string.txt'));
ok($fh);
