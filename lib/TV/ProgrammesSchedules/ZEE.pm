package TV::ProgrammesSchedules::ZEE;

use strict; use warnings;

use overload q("") => \&as_string, fallback => 1;

use Carp;
use Readonly;
use Data::Dumper;
use LWP::UserAgent;
use Time::localtime;
use HTTP::Request::Common;

=head1 NAME

TV::ProgrammesSchedules::ZEE - Interface to ZEE TV Programmes Schedules.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';
our $DEBUG   = 0;

Readonly my $BASE_URL => 'http://www.zeetv.com/schedule/';

=head1 DESCRIPTION

Zee TV, the flagship channel of Zee Network was launched in October 1992. With a reach of more
than  120  countries  and access to more than 500 million viewers globally, Zee TV has created
strong  brand equity and is the largest media franchise serving the South Asian Diaspora. With 
over  sixteen  years  of  its  launch, Zee TV has driven the growth of the satellite and cable 
industry in India.

The  popularity  of  Zee arises from its understanding of Indian culture and beliefs which are 
depicted  in  its  programming.  Realizing its strength in programming and the need for Indian 
entertainment  in  the overseas market, the company launched Zee TV in the UK / Europe (1995), 
the USA (1998), Africa (1998) and today is available across five continents.

=head1 CONSTRUCTOR

The constructor optionally expects a reference to anonymous hash as input parameter.  Possible
keys  to the anonymous hash are ( yyyy, mm, dd ). The yyyy, mm and dd are optional. If missing
picks up the current year, month and day.

    use strict; use warnings;
    use TV::ProgrammesSchedules::ZEE;
    
    my $zee_today = TV::ProgrammesSchedules::ZEE->new();
    my $zee_2011_04_25 = TV::ProgrammesSchedules::ZEE->new({yyyy=>2011,mm=>4,dd=>25});

=cut

sub new
{
    my $class = shift;
    my $param = shift;
    
    croak("ERROR: Input param has to be a ref to HASH.\n")
        if (defined($param) && (ref($param) ne 'HASH'));
    croak("ERROR: Invalid number of keys found in the input hash.\n")
        if (defined($param) && (scalar(keys %{$param}) != 3));

    $param->{_browser} = LWP::UserAgent->new();
    unless (defined($param) && defined($param->{yyyy}) && defined($param->{mm}) && defined($param->{dd}))
    {
        my $today = localtime; 
        $param->{yyyy} = $today->year+1900;
        $param->{mm}   = $today->mon+1;
        $param->{dd}   = $today->mday;
    }
    
    _validate_date($param->{yyyy}, $param->{mm}, $param->{dd});
    bless $param, $class;
    return $param;
}

=head1 METHODS

=head2 get_listings()

Return the programmes listings for the given date. Data would be in the form of reference to a
list containing anonymous hash with keys time, title & url, if any, for each of the programme.

    use strict; use warnings;
    use TV::ProgrammesSchedules::ZEE;
    
    my $zee = TV::ProgrammesSchedules::ZEE->new();
    my $listings = $zee->get_listings();

=cut

sub get_listings
{
    my $self = shift;
    
    my ($url, $browser, $response);
    $browser = $self->{_browser};
    $url  = sprintf("%s?sdate=%04d-%02d-%02d", $BASE_URL, $self->{yyyy}, $self->{mm}, $self->{dd});
    $response = $browser->request(GET $url);
    croak("ERROR: Couldn't connect to [$url].\n")  unless $response->is_success;
    print {*STDOUT} "Fetch programmes listing using URL [$url] ...\n"
        if $DEBUG;
        
    my ($contents, $listings, $program, $count, $time, $title);
    $time     = undef;
    $title    = 0;
    $contents = $response->content;
    foreach (split /\n/,$contents)
    {
        s/^\s+//g;
        s/\s+$//g;
        s/\s+/ /g;
        if (/\<span class\=\"time_schedule\"\>(.*?)\<\/span\>/)
        {
            $time = $1;
        }
        elsif (/\<span class\=\"showtitle_schedule\"\>/)
        {
            $title = 1;
        }
        elsif (defined($time) && ($title))
        {
            if ($_ !~ /^\<h2\>/)
            {
                if (/\<a href\=\"(.*?)\"\s*\>(.*)\<\/a\>/)
                {
                    $title = $2;
                    my $_url = $1;
                    $_url =~ s/(.*)?\" target\=\"(.*)$/$1/;
                    push @$listings, { time => $time, title => $title, url => $_url };
                }
                else
                {
                    push @$listings, { time => $time, title => $_ };
                }
                $title = 0;
                $time  = undef;
            }    
        }
    }
    
    $self->{$listings} = $listings;
    return $listings;
}

=head2 as_xml()

Returns listings in XML format. By default it returns todays lisitng for ZEE TV.

    use strict; use warnings;
    use TV::ProgrammesSchedules::ZEE;

    my $zee = TV::ProgrammesSchedules::ZEE->new();
    print $zee->as_xml();

=cut

sub as_xml
{
    my $self = shift;
    my ($xml, $listings);
    
    $self->{listings} = $self->get_listings()
        unless defined($self->{listings});

    $xml = qq {<?xml version="1.0" encoding="UTF-8"?>\n};
    $xml.= qq {<programmes>\n};
    foreach (@{$self->{listings}})
    {
        $xml .= qq {\t<programme>\n};
        $xml .= qq {\t\t<time> $_->{time} </time>\n};
        $xml .= qq {\t\t<title> $_->{title} </title>\n};
        $xml .= qq {\t\t<url> $_->{url} </url>\n} if exists($_->{url});
        $xml .= qq {\t</programme>\n};        
    }
    $xml.= qq {</programmes>};
    return $xml;
}

=head2 as_string()

Returns listings in a human readable format. By default it returns todays lisitng for ZEE TV.

    use strict; use warnings;
    use TV::ProgrammesSchedules::ZEE;

    my $zee      = TV::ProgrammesSchedules::ZEE->new();
    my $listings = $zee->get_listings();

    print $zee->as_string();

    # or even simply
    print $zee;

=cut

sub as_string
{
    my $self = shift;
    my ($listings);
    
    $self->{listings} = $self->get_listings()
        unless defined($self->{listings});

    foreach (@{$self->{listings}})
    {
        $listings .= sprintf(" Time: %s\n", $_->{time});
        $listings .= sprintf("Title: %s\n", $_->{title});
        $listings .= sprintf("  URL: %s\n", $_->{url}) if exists($_->{url});
        $listings .= "-------------------\n";
    }
    return $listings;
}

sub _validate_date
{
    my $yyyy = shift;
    my $mm   = shift;
    my $dd   = shift;

    croak("ERROR: Invalid year [$yyyy].\n")
        unless (defined($yyyy) && ($yyyy =~ /^\d{4}$/) && ($yyyy > 0));
    croak("ERROR: Invalid month [$mm].\n")
        unless (defined($mm) && ($mm =~ /^\d{1,2}$/) && $mm >= 1 && $mm <= 12);
    croak("ERROR: Invalid day [$dd].\n")
        unless (defined($dd) && ($dd =~ /^\d{1,2}$/) && $dd >= 1 && $dd <= 31);
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 BUGS

Please report any bug or feature requests to C<bug-tv-programmesschedules-zee at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=TV-ProgrammesSchedules-ZEE>.  
I will be notified and then you'll automatically be notified of progress on your bug as I make 
changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc TV::ProgrammesSchedules::ZEE

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=TV-ProgrammesSchedules-ZEE>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/TV-ProgrammesSchedules-ZEE>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/TV-ProgrammesSchedules-ZEE>

=item * Search CPAN

L<http://search.cpan.org/dist/TV-ProgrammesSchedules-ZEE/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Mohammad S Anwar.

This  program  is  free  software; you can redistribute it and/or modify it under the terms of
either:  the  GNU  General Public License as published by the Free Software Foundation; or the
Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 DISCLAIMER

This  program  is  distributed  in  the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

1; # End of TV::ProgrammesSchedules::ZEE