#!/usr/bin/env perl 

use strict;
use warnings;
use FindBin;

use Test::More;
use Test::Fatal;

BEGIN {
	use_ok('Directory::Scanner');
}

my $ROOT = $FindBin::Bin.'/data/';

subtest '... twisted filtered stream test' => sub {

	my @c;
	my $c = sub { push @c => $_[0]->relative( $ROOT ) };

	my $stream = Directory::Scanner->for( $ROOT )
					  			   ->recurse
					  			   ->filter( sub { (shift)->is_file })
					  			   ->apply($c)
					  	           ->stream;
	isa_ok($stream, 'Directory::Scanner::Stream::Application');

	ok(!$stream->is_done, '... the stream is not done');
	ok(!$stream->is_closed, '... the stream is not closed');
	ok(!defined($stream->head), '... nothing in the head of the stream');	

	my @all;
	while ( my $i = $stream->next ) {
		push @all => $i->relative( $ROOT );
		is($i, $stream->head, '... the head is the same as the value returned by next');
	}

	is_deeply(
		[ sort @all ], 
		[qw[ 
			lib/Foo.pm			
			lib/Foo/Bar.pm
			lib/Foo/Bar/Baz.pm					
			t/000-load.pl
			t/001-basic.pl
		]], 
		'... got the list of directories'
	);

	is_deeply([ sort @all ], [ sort @c ], '... list of directories is same as apply collected');

	ok($stream->is_done, '... the stream is done');
	ok(!$stream->is_closed, '... but the stream is not closed');
	ok(!defined($stream->head), '... nothing in the head of the stream');

	is(exception { $stream->close }, undef, '... closed stream successfully');

	ok($stream->is_closed, '... the stream is closed');	
};

subtest '... twisted filtered stream test with flatten' => sub {

	my @c;
	my $c = sub { push @c => $_[0]->relative( $ROOT ) };

	my $stream = Directory::Scanner->for( $ROOT )
					  			   ->recurse
					  			   ->filter( sub { (shift)->is_file })
					  			   ->apply($c)
					  	           ->stream;
	isa_ok($stream, 'Directory::Scanner::Stream::Application');

	ok(!$stream->is_done, '... the stream is not done');
	ok(!$stream->is_closed, '... the stream is not closed');
	ok(!defined($stream->head), '... nothing in the head of the stream');	

	my @all = map $_->relative( $ROOT ), $stream->flatten;

	is_deeply(
		[ sort @all ], 
		[qw[ 
			lib/Foo.pm			
			lib/Foo/Bar.pm
			lib/Foo/Bar/Baz.pm					
			t/000-load.pl
			t/001-basic.pl
		]], 
		'... got the list of directories'
	);

	is_deeply([ sort @all ], [ sort @c ], '... list of directories is same as apply collected');

	ok($stream->is_done, '... the stream is done');
	ok(!$stream->is_closed, '... but the stream is not closed');
	ok(!defined($stream->head), '... nothing in the head of the stream');

	is(exception { $stream->close }, undef, '... closed stream successfully');

	ok($stream->is_closed, '... the stream is closed');	
};

done_testing;
