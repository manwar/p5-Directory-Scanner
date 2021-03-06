package Directory::Scanner;
# ABSTRACT: Streaming directory scanner

use strict;
use warnings;

use Carp         ();
use Scalar::Util ();

use Directory::Scanner::API::Stream;

use Directory::Scanner::Stream;

use Directory::Scanner::StreamBuilder::Concat;
use Directory::Scanner::StreamBuilder::Recursive;
use Directory::Scanner::StreamBuilder::Matching;
use Directory::Scanner::StreamBuilder::Ignoring;
use Directory::Scanner::StreamBuilder::Application;
use Directory::Scanner::StreamBuilder::Transformer;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

## static builder constructors

sub for {
	my (undef, $dir) = @_;
	return bless [ $dir ] => __PACKAGE__;
}

sub concat {
	my (undef, @streams) = @_;

	Carp::confess 'You provide at least two streams to concat'
		if scalar @streams < 2;

	return Directory::Scanner::StreamBuilder::Concat->new( streams => [ @streams ] );
}

## builder instance methods

sub recurse {
	my ($builder) = @_;
	push @$builder => [ 'Directory::Scanner::StreamBuilder::Recursive' ];
	return $builder;
}

sub ignore {
    my ($builder, $filter) = @_;
    # XXX - should this support using at .gitignore files?
    push @$builder => [ 'Directory::Scanner::StreamBuilder::Ignoring', filter => $filter ];
    return $builder;
}

sub match {
	my ($builder, $predicate) = @_;
	push @$builder => [ 'Directory::Scanner::StreamBuilder::Matching', predicate => $predicate ];
	return $builder;
}

sub apply {
	my ($builder, $function) = @_;
	push @$builder => [ 'Directory::Scanner::StreamBuilder::Application', function => $function ];
	return $builder;
}

sub transform {
	my ($builder, $transformer) = @_;
	push @$builder => [ 'Directory::Scanner::StreamBuilder::Transformer', transformer => $transformer ];
	return $builder;
}

## builder method

sub stream {
	my ($builder) = @_;

	if ( my $dir = shift @$builder ) {
		my $stream = Directory::Scanner::Stream->new( origin =>  $dir );

		foreach my $layer ( @$builder ) {
			my ($class, %args) = @$layer;
			$stream = $class->new( stream => $stream, %args );
		}

		return $stream;
	}
	else {
		Carp::confess 'Nothing to construct a stream on';
	}
}

1;

__END__

=pod

=head1 SYNOPSIS

	# get all entries in a directory

	Directory::Scanner->for( $dir )->stream;

	# get all entries in a directory recursively

	Directory::Scanner->for( $dir )
					  ->recurse
					  ->stream;

	# get all entries in a directory recusively
	# and filter out anything that is not a directory

	Directory::Scanner->for( $dir )
					  ->recurse
					  ->match(sub { $_->is_dir })
					  ->stream;

	# ignore anything that is a . directory, then recurse

	Directory::Scanner->for( $dir )
					  ->ignore(sub { $_->basename =~ /^\./ })
					  ->recurse
					  ->stream;


=cut


