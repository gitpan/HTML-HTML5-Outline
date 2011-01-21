package HTML::HTML5::Outline::Section;

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
sub elements { return @{ $_[0]->{elements} }; }
sub header   { return $_[0]->{header}; }
sub heading  { return $_[0]->{heading}; }
sub order    { return $_[0]->{document_order}; }
sub outliner { return $_[0]->{outliner}; }
sub sections { return @{ $_[0]->{sections} }; }

sub children
{
	my ($self) = @_;
	my @rv = $self->sections;
	
	foreach my $e ($self->elements)
	{
		my $E = HTML::HTML5::Outline::k($e);
		if ($self->outliner->{outlines}->{$E})
		{
			push @rv, $self->outliner->{outlines}->{$E};
		}
	}

	return sort { $a->order <=> $b->order } @rv;
}

sub add_to_model
{
	my ($self, $model) = @_;

	$self->{trine_node}            = my $self_node   = RDF::Trine::Node::Blank->new;
	$self->{trine_node_for_header} = my $header_node = $self->outliner->_node_for_element($self->header);

	$model->add_statement(RDF::Trine::Statement->new(
		$self_node,
		RDF::Trine::Node::Resource->new(PROP_TITLE),
		RDF::Trine::Node::Literal->new($self->heading, $self->outliner->_node_lang($self->header)),
		));

	$model->add_statement(RDF::Trine::Statement->new(
		$self_node,
		RDF::Trine::Node::Resource->new(REL_TYPE),
		RDF::Trine::Node::Resource->new(TYPE_TEXT),
		));
	
	$model->add_statement(RDF::Trine::Statement->new(
		$self_node,
		RDF::Trine::Node::Resource->new(REL_HEADING),
		$header_node,
		));
		
	$model->add_statement(RDF::Trine::Statement->new(
		$header_node,
		RDF::Trine::Node::Resource->new(PROP_TAG),
		RDF::Trine::Node::Literal->new($self->header->tagName, undef, NMTOKEN),
		));

	my @partlist;
	foreach my $child (@{$self->{sections}})
	{
		$model->add_statement(RDF::Trine::Statement->new(
			$self_node,
			RDF::Trine::Node::Resource->new(REL_PART),
			$child->add_to_model($model),
			));
		push @partlist, $child;
	}

	foreach my $e (@{$self->{elements}})
	{
		my $E = HTML::HTML5::Outline::k($e);
		
		if ($self->outliner->{outlines}->{$E})
		{
			my $rel = REL_IPART;
			$rel = REL_ASIDE   if lc $e->tagName eq 'aside';
			$rel = REL_BQ      if lc $e->tagName eq 'blockquote';
			$rel = REL_FIGURE  if lc $e->tagName eq 'figure';
			$rel = REL_SECTION if lc $e->tagName eq 'section';
			
			$model->add_statement(RDF::Trine::Statement->new(
				$self_node,
				RDF::Trine::Node::Resource->new($rel),
				$self->outliner->{outlines}->{$E}->add_to_model($model),
				));
				
			push @partlist, $self->outliner->{outlines}->{$E};
		}
	}

	$self->outliner->_add_partlist_to_model($self, $model, @partlist);

	return $self_node;
}

sub to_hashref
{
	my ($self) = @_;

	my $header_node  = {
		class      => 'Header',
		tag        => $self->header->tagName,
		content    => $self->heading,
		lang       => $self->outliner->_node_lang($self->header),
		};
	my $section_node = {
		class      => 'Section',
		type       => 'Text',
		header     => $header_node,
		};

	$self->{hashref_node}            = $section_node;
	$self->{hashref_node_for_header} = $header_node;
	
	$section_node->{children} = [ map { $_->to_hashref } $self->children ];

	return $section_node;
}

1;


__END__

=head1 NAME

HTML::HTML5::Outline::Section - represents a document section

=head1 DESCRIPTION

=head2 Methods

=over

=item * C<< element >>

An L<XML::LibXML::Element> for the section.

=item * C<< elements >>

Various L<XML::LibXML::Element> objects which are within the section.

=item * C<< header >>

The L<XML::LibXML::Element> which represents the heading for the section.

=item * C<< heading >>

The text of the heading for the section.

=item * C<< order >>

The order of the section relative to other sections and outlinees.

=item * C<< sections >>

Child sections of this section.

=item * C<< children >>

Child sections of this section, and outlinees within this section,
sorted in document order.

=back

=head1 SEE ALSO

L<HTML::HTML5::Outline::Outlinee>,
L<HTML::HTML5::Outline>.

=head1 AUTHOR

Toby Inkster, E<lt>tobyink@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2008-2011 by Toby Inkster

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
