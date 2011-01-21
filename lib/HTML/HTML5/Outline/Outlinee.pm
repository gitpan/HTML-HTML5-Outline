package HTML::HTML5::Outline::Outlinee;

use 5.008;
use common::sense;

use constant NMTOKEN        => 'http://www.w3.org/2001/XMLSchema#NMTOKEN';
use constant PROP_TITLE     => 'http://purl.org/dc/terms/title';
use constant PROP_TAG       => 'http://ontologi.es/outline#tag';
use constant RDF_FIRST      => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#first';
use constant RDF_REST       => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#rest';
use constant RDF_NIL        => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#nil';
use constant REL_ASIDE      => 'http://ontologi.es/outline#aside';
use constant REL_BQ         => 'http://ontologi.es/outline#blockquote';
use constant REL_FIGURE     => 'http://ontologi.es/outline#figure';
use constant REL_HEADING    => 'http://ontologi.es/outline#heading';
use constant REL_IPART      => 'http://ontologi.es/outline#ipart';
use constant REL_PART       => 'http://ontologi.es/outline#part';
use constant REL_PARTLIST   => 'http://ontologi.es/outline#part-list';
use constant REL_SECTION    => 'http://ontologi.es/outline#section';
use constant REL_TYPE       => 'http://purl.org/dc/terms/type';
use constant TYPE_DATASET   => 'http://purl.org/dc/dcmitype/Dataset';
use constant TYPE_IMAGE     => 'http://purl.org/dc/dcmitype/Image';
use constant TYPE_TEXT      => 'http://purl.org/dc/dcmitype/Text';

our $VERSION = '0.003';

sub new
{
	my ($class, %data) = @_;

	$data{header}   ||= undef;
	$data{parent}   ||= undef;
	$data{elements} ||= [];

	bless { %data }, $class;
}

sub element  { return $_[0]->{element}; }
sub order    { return $_[0]->{document_order}; }
sub outliner { return $_[0]->{outliner}; }
sub sections { return @{ $_[0]->{sections} }; }

sub children
{
	my ($self) = @_;
	return sort { $a->order <=> $b->order } $self->sections;
}

sub add_to_model
{
	my ($self, $model) = @_;

	my $rdf_type = TYPE_TEXT;
	
	if ($self->element->localname eq 'figure'
	||  $self->element->getAttribute('class') =~ /\bfigure\b/)
	{
		$rdf_type = TYPE_IMAGE;
	}
	elsif ($self->element->localname =~ /^(ul|ol)$/i
	&&     $self->element->getAttribute('class') =~ /\bxoxo\b/)
	{
		$rdf_type = TYPE_DATASET;
	}

	my $self_node = $self->outliner->_node_for_element($self->element);
	$self->{trine_node} = $self_node;
	
	if ($self->element->localname =~ /^(body|html)$/i) 
	{
		$self_node = RDF::Trine::Node::Resource->new($self->outliner->{options}->{uri});
	}
	
	$model->add_statement(RDF::Trine::Statement->new(
		$self_node,
		RDF::Trine::Node::Resource->new(PROP_TAG),
		RDF::Trine::Node::Literal->new($self->element->localname, undef, NMTOKEN),
		))
		unless $self->element->localname =~ /^(body|html)$/i;

	$model->add_statement(RDF::Trine::Statement->new(
		$self_node,
		RDF::Trine::Node::Resource->new(REL_TYPE),
		RDF::Trine::Node::Resource->new($rdf_type),
		));
		
	my @partlist;
	foreach my $section (@{$self->{sections}})
	{
		$model->add_statement(RDF::Trine::Statement->new(
			$self_node,
			RDF::Trine::Node::Resource->new(REL_PART),
			$section->add_to_model($model),
			));
		push @partlist, $section;
	}
	$self->outliner->_add_partlist_to_model($self, $model, @partlist);

	return $self_node;
}

sub to_hashref
{
	my ($self) = @_;

	my $rdf_type = 'Text';
	
	if ($self->element->tagName eq 'figure'
	||  $self->element->getAttribute('class') =~ /\bfigure\b/)
	{
		$rdf_type = 'Image';
	}
	elsif ($self->element->tagName =~ /^(ul|ol)$/i
	&&     $self->element->getAttribute('class') =~ /\bxoxo\b/)
	{
		$rdf_type = 'Dataset';
	}

	my $outline_node = {
		class    => 'Outline',
		type     => $rdf_type,
		tag      => $self->element->tagName,
		};
	
	foreach my $section (@{$self->{sections}})
	{
		push @{ $outline_node->{children} }, $section->to_hashref;
	}
	
	return $outline_node;
}

1;


__END__

=head1 NAME

HTML::HTML5::Outline::Outlinee - an element with an independent outline

=head1 DESCRIPTION

Elements like E<lt>blockquoteE<gt> have their own independent outline,
which is nested within the primary outline somewhere.

=head2 Methods

=over

=item * C<< element >>

An L<XML::LibXML::Element> for the outlinee.

=item * C<< order >>

The order of the outlinee relative to sections and other outlinees.

=item * C<< sections >>

Sections of this outlinee.

=item * C<< children >>

Sections of this outlinee, sorted in document order.

=back

=head1 SEE ALSO

L<HTML::HTML5::Outline::Section>,
L<HTML::HTML5::Outline>.

=head1 AUTHOR

Toby Inkster, E<lt>tobyink@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2008-2011 by Toby Inkster

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
