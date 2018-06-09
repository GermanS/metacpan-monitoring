use Compress::Zlib;
use HTTP::Request::Common;
use LWP::UserAgent;
use Test::More;
use XML::LibXML;

set_response_processor(
    sub {
        my ($headers, $body) = @_;

        my $xml_string = unzip($body);
        check_xml($xml_string);
        check_sitemap($xml_string);

        return;
    }
);


sub unzip {
    my ($raw) = @_;

    my $data = Compress::Zlib::memGunzip(\$raw);

    ok($data, 'archive unzipped');

    return $data;
}

sub check_xml {
    my ($xml_string) = @_;

    eval {
        my $parser = XML::LibXML->new();
        $parser->parse_string($xml_string);
    };

    ok(!$@, 'XML valid');

    return;
}

sub check_sitemap {
    my ($xml_string) = @_;

    while ($xml_string =~ /\<loc\>(.+?)\<\/loc\>/gxo) {
        my $url = $1;

        check($url);
    }

    return;
}

sub check {
    my ($url) = @_;

    # NOTE: SWAT could run simple tests

    # One way for automation
    # > mkdir sitemap-releases.xml.gz/any
    # > echo 200 > sitemap-releases.xml.gz/any/get.txt
    # > echo 'swat_module=0' sitemap-releases.xml.gz/any/swat.ini
    # > swat sitemap-releases.xml.gz/any https://metacpan.org/release/AI-XGBoost/

    # use IPC::Run qw(run);
    # my @cmd = ( 'swat', 'sitemap-releases.xml.gz/any', $url );
    # run( @cmd ) || die "cant start $?\n";


    my $response = ua()->request(HEAD $url);

    ok($response->is_success(), sprintf("%s %s", $response->status_line(), $url));

    return;
}

{
    my $ua;

    sub ua {

        if (!$ua) {
            $ua = LWP::UserAgent->new();
        }

        return $ua;
    }
}
