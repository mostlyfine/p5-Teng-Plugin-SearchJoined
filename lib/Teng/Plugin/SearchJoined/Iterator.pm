package Teng::Plugin::SearchJoined::Iterator;
use strict;
use warnings;
use Carp ();
use Class::Accessor::Lite (
    new => 1,
    ro  => [qw/teng sql table_names fields/],
    rw  => [qw/sth suppress_object_creation/],
);

sub _row_class {
    my ($self, $table) = @_;
    $self->{_row_class}{$table} ||= $self->{teng}{schema}->get_row_class($table);
}

sub next {
    my $self = shift;

    my $row;
    if ($self->{sth}) {
        $row = $self->{sth}->fetchrow_arrayref;
        unless ( $row ) {
            $self->{sth}->finish;
            $self->{sth} = undef;
            return;
        }
    } else {
        return;
    }

    my $data = $self->_seperate_rows($row);

    if ($self->{suppress_object_creation}) {
        return @$data{ @{$self->{table_names}} };
    } else {
        return map {$self->_row_class($_)->new({
            sql            => $self->{sql},
            row_data       => $data->{$_},
            teng           => $self->{teng},
            table_name     => $_,
        }) } @{$self->{table_names}};
    }
}
sub all {
    my $self = shift;

    my $result = [];
    while(my @tables = $self->next) {
        my %table = map {$_->{table_name} => $_} @tables;
        push @$result, \%table;
    }

    return wantarray ? @$result : $result;
}

sub _seperate_rows {
    my ($self, $row) = @_;
    my %data;
    my $name_sep = quotemeta $self->{teng}{sql_builder}{name_sep};
    my $i = 0;
    for my $field (@{ $self->{fields} }) {
        my $value = $row->[$i++];
        my ($table, $column) = split /$name_sep/, $field;
        $data{$table}{$column} = $value;
    }
    \%data;
}

1;
__END__

=encoding utf-8

=head1 NAME

Teng::Plugin::SearchJoined::Iterator - Iterator for Teng::Plugin::SearchJoined

=head1 SYNOPSIS

    my $itr = $db->search_joined(...);
    while ( my ($row1, $row2,...) = $itr->next ) {
        ...
    }

    my $itr = $db->search_joined(...);
    $itr->suppress_object_creation;
    while ( my ($row_hash2, $row_hash2,...) = $itr->next ) {
        ...
    }

=head1 DESCRIPTION

Teng::Plugin::SearchJoined::Iterator is an Iterator for Teng::Plugin::SearchJoined.

=head1 INTERFACE

=head2 Method

=head3 C<< ($row1, $row2...) = $itr->next >>

Get next data of row objects.

=head3 C<< $itr->suppress_object_creation($bool) >>

Set row object creation mode.

=head1 LICENSE

Copyright (C) Masayuki Matsuki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masayuki Matsuki E<lt>y.songmu@gmail.comE<gt>

=cut

