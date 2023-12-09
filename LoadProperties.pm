package LoadProperties;
use CGI::Carp qw(fatalsToBrowser); 
use MIME::Lite;
use Switch;
use Digest::MD5 qw(md5_hex);
use DBI;
use GD;
use Image::GD::Thumbnail;
use Time::HiRes qw(gettimeofday);
use Date::Manip;
use GD::Graph::bars;
use DateTime;
use POSIX qw(strftime);
use POSIX qw[tzset];
use CGI::Session qw/-ip-match/;
use Compress::Zlib;
use Email::Valid;
use MyDB;
use vars qw (%ENV $session_dir $can_do_gzip $cookie $page $dir $dirLang $dirError $imgdir $action $t0 $session_id $ycan_do_gzip $current_ip $lang $LANG %ARTICLE %SESSION %SERVER %USER $CGISESSID %LABEL %ERROR %VALUE $COMMANDID %COMMAND %DATE %PAYPALL $INDEX %LINK  $query $session $host $t0  $client);

$query = CGI->new ;
$cookie = "";
$current_ip = $ENV{'REMOTE_ADDR'};
$client = $ENV{'HTTP_USER_AGENT'};
$t0 = gettimeofday();
$host = "http://127.0.0.1";
%ERROR = ();%LABEL = ();$LANG = "";%LINK = ();%ARTICLE = ();%SESSION = ();
my %SERVER = (); 
$action = $query->param('action');
$page = $query->param("page");
$session_id  =  $query->param('session');
$can_do_gzip = ($ENV{'HTTP_ACCEPT_ENCODING'} =~ /gzip/i) ? 1 : 0;
$dir = "C:/Users/41786/OneDrive/Documents/recordz1/";
$dirLang = "C:/Users/41786/OneDrive/Documents/recordz1/lang";
$dirError = "C:/Users/41786/OneDrive/Documents/recordz1/lang";
$imgdir=  "C:/Users/41786/OneDrive/Documents/recordz1/upload";
$session_dir = "C:/Users/41786/OneDrive/Documents/recordz1/sessions";
$action = $query->param('action');
$session_id = $query->param('session');

use Article;
use SharedVariable;
#use Initialize ;

my $db = MyDB->new;
my $articleClass = Article->createArticle();

sub create {
    my $class = shift;
    my ($opts) = @_;
	my $self = {};
	return bless $self, $class;
}


sub trimwhitespace($) {
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

sub loadIsBuyOrLocationValue {
	my $string;
	$string .= "<tr><td align=\"left\">$SERVER{'label_location_or_buy'}</td><td align=\"left\"><select name=\"is_location_or_buy\">";
	$string .= "<option>$SERVER{'location'}</option><option>$SERVER{'buy'}</option></select></td></tr>";
	return $string;
}


sub getLinkImmobilierInterest {
	my $article = $query->param("article");my $string ;
	$string .= "<a href=\"#\" class=\"menulink\" class=&{ns4class}; onclick=\"window.open('/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&page=askvisit&amp;article=$article','MyWindow3','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=no,width=530,height=650,left=20,top=20')\">Demander une visite</a><br/>";
	return $string;
}
sub loadCityLocationValue {
	my $string;my $canton = shift || '';my $lieu = shift || '';my $nb_piece = shift || '';my $habitable_surface = shift || '';my $location_ou_achat = shift || '';my $adresse = shift || '';
	my $npa = shift || '';my $city = shift || '';
	my $country = shift || '';
	$string .= "<tr>";
	$string .= "<td align=\"left\">$SERVER{'label_location_or_buy'}</td>";
	$string .= "<td align=\"left\"><input type=\"text\" name=\"location_ou_achat\" value=\"$location_ou_achat\"></td>";
	$string .= "</tr>";
	$string .= "<td align=\"left\">$SERVER{'canton'}</td>";$string .= "<td align=\"left\"><input type=\"text\" name=\"canton\" value=\"$canton\"></td>";$string .= "</tr>";
	$string .= "<tr>";$string .= "<td align=\"left\">$SERVER{'city_label'}</td>";$string .= "<td align=\"left\"><input type=\"text\" name=\"location_place\" value=\"$lieu\"></td>";$string .= "</tr>";$string .= "<tr>";$string .= "<td align=\"left\">$SERVER{'adress'}</td>";
	$string .= "<td align=\"left\">$adresse</td>";
	if ($country eq 'Suisse') {$string .= "<td align=\"left\"><a href=\"javascript:void(0)\" class=\"menulink\"  onclick=\"window.open('http://map.search.ch/$npa-$city/$adresse','MyWindow','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=no,width=800,height=600,left=20,top=20')\">Trouver sur la carte</a></td>";
	}elsif ($country eq 'France') {$string .= "<td align=\"left\"><a href=\"javascript:void(0)\" class=\"menulink\"  onclick=\"window.open('http://www.maporama.com/affiliates/popup/share/Map.asp?_XgoGCAdrCommand=run&language=$lang&_XgoGCAddress=$adresse+%E9curies&Zip=$npa&_XgoGCTownName=$city&COUNTRYCODE=FR&submit.x=57&submit.y=10','MyWindow','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=no,width=800,height=600,left=20,top=20')\">Trouver sur la carte</a></td>";}
	$string .= "</tr>";
	$string .= "<tr><td align=\"left\">$SERVER{'nbr_piece'}</td>";
	$string .= "<td align=\"left\"><input type=\"text\" name=\"nbr_piece\" value=\"$nb_piece\"></td>";
	$string .= "</tr>";
	$string .= "<tr><td align=\"left\">$SERVER{'habitable_surface'}</td>";
	$string .= "<td align=\"left\"><input type=\"text\" name=\"habitable_surface\" value=\"$habitable_surface\"></td>";
	$string .= "</tr>";
	return $string;
}


sub loadInstrumentCategory {
    my $u = $query->param("u");
    $lang = $query->param("lang");
    my  ($c)= $db->sqlSelectMany("libelle.libelle",
			   "categorie_libelle_langue, libelle,langue",
			   "(ref_categorie = 92  or ref_categorie = 93) AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my $selected = $query->param("category");
    my $string = "<select name=\"category\" onchange=\"go();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("category");
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {	
         $string .= "<option VALUE=\"/cgi-bin/m.pl?lang=$lang&amp;page=intruments&sesssion=$session_id&u=$u&category=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select>";
    return $string;    
       
}

sub loadCollectionCategories {
    $lang = $query->param("lang");
    my  ($c)= $db->sqlSelectMany("libelle.libelle",
			   "subcategorie_libelle_langue, libelle,langue",
			   "(ref_categorie = 18) AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my $selected = $query->param("subcategory");
    my $string = "<select name=\"subcategory\" onchange=\"go2();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {	
         $string .= "<option VALUE=\"/cgi-bin/n.pl?lang=$lang&amp;page=collection&sesssion=$session_id&subcategory=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select>";
    return $string;    
       
}

sub loadSearchCollectionCategory {
    $lang = $query->param("lang");
     my  ($c)= $db->sqlSelectMany("libelle.libelle",
			   "subcategorie_libelle_langue, libelle,langue",
			   "(ref_categorie = 18) AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my $selected = $query->param("subcat");
    my $string = "<select name=\"subcat\" onchange=\"go3();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {	
        $string .= "<option VALUE=\"/cgi-bin/n.pl?lang=$lang&amp;page=collection&show_popup=true&session=$session_id&subcat=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select>";
    return $string;    
   
}
sub loadInstrumentSubCategory {
    $lang = $query->param("lang");
    loadLanguage();
    my $category = $query->param("category");
    my ($a) = $db->sqlSelect("ref_categorie","categorie_libelle_langue, langue, libelle","libelle.libelle = '$category' and categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my  ($c);
    my $selected = $query->param("subcategory");
    my $string = "<select name=\"subcategory\" onchange=\"go2();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("category");
    $string  .= "<option selected value=\"$selected\">$selected</option>";
    $string  .= "<option value=\"\">--------</option>";

    if ($a) {
	my  ($c)= $db->sqlSelectMany("libelle.libelle","subcategorie_libelle_langue, libelle, langue","subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle and subcategorie_libelle_langue.ref_categorie = $a");
        my  %OPTIONS = ();    
        while(($OPTIONS{'category'})=$c->fetchrow()) {	
             $string .= "<option VALUE=\"/cgi-bin/m.pl?lang=$lang&amp;page=intruments&session=$session_id&subcategory=$OPTIONS{'category'}&category=$category\">$OPTIONS{'category'}</option>" ;
	}
    }    
    $string .= "</select>";
    return $string;        
}

sub loadLingerieCategory {
    my $u = $query->param("u");
    $lang = $query->param("lang");
    my  ($c)= $db->sqlSelectMany("libelle.libelle",
			   "categorie_libelle_langue, libelle,langue",
			   "(ref_categorie = 21  or ref_categorie = 31) AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my $selected = $query->param("category");
    my $string = "<select name=\"category\" onchange=\"go();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("category");
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {	
         $string .= "<option VALUE=\"/cgi-bin/d.pl?lang=$lang&amp;page=lingerie&session=$session_id&u=$u&category=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select>";
    return $string;    
    
}

sub loadSearchArtCategories {
    my $u = $query->param("u");
    my  ($c)= $db->sqlSelectMany("libelle.libelle",
			   "categorie_libelle_langue, libelle,langue",
			   "(ref_categorie = 0) AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my $selected = $query->param("category");
    my $string = "<select name=\"category\" onchange=\"go();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("category");
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {	
         $string .= "<option VALUE=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=search_art&show_popup=true&session=$session_id&category=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select>";
    return $string;    
    
}
sub loadLingerieSubCategory {
    my $u = $query->param("u");
    my $category = $query->param("category");	
    my  ($c)= $db->sqlSelectMany("DISTINCT libelle.libelle","subcategorie_libelle_langue, libelle, langue","subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' AND subcategorie_libelle_langue.ref_categorie = (SELECT categorie_libelle_langue.ref_categorie FROM categorie_libelle_langue, libelle, langue WHERE libelle.libelle ='$category' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang')");
    my $selected = $query->param("subcat");
    my $string = "<select name=\"subcat\" onchange=\"go2();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {	
         $string .= "<option VALUE=\"/cgi-bin/d.pl?lang=$lang&amp;page=lingerie&u=$u&session=$session_id&category=$category&subcat=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select>";
    return $string;        
    
}

sub loadSearchArtSubCategory {
    my $u = $query->param("u");
    $lang = $query->param("lang");
    loadLanguage();
    my $category = $query->param("category");	
    my  ($c)= $db->sqlSelectMany("DISTINCT libelle.libelle","subcategorie_libelle_langue, libelle, langue","subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' AND subcategorie_libelle_langue.ref_categorie = 0");
    my $selected = $query->param("subcat");
    my $string = "<td>$LABEL{'subcategory'}</td><td><select name=\"subcat\" onchange=\"go2();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {	
         $string .= "<option VALUE=\"/cgi-bin/a.pl?lang=$lang&show_popup=true&&amp;page=art_design&session=$session_id&category=$category&subcat=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select></td>";
    return $string;        
    
}

sub loadSearchArtFabricant {
	loadLanguage();
    my $category = $query->param("category");
    my $subcategory = $query->param("subcat");
    my $fabricant = $query->param("fabricant");
    my $type = $query->param("type");
    my $string .= "<td align=\"left\">$SERVER{'fabricant'}</td>";
    $string .= "<td align=\"left\"><select name=\"fabricant\" onchange=\"go3();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    
    if ($subcategory) {
	#code
    
    
    
    my  ($c)= $db->sqlSelectMany("DISTINCT marque",
			   "article,subcategorie_libelle_langue, libelle, langue",
			   "article.ref_categorie = 0 AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_libelle = (SELECT id_libelle FROM libelle WHERE libelle = '$subcategory')");
    
    
    my  %OPTIONS = ();

    
    if ($fabricant) {
	$string  .= "<option selected value=\"$fabricant\" onblur=\"skipcycle=false\">$fabricant</option>";
    }
    $string  .= "<option value=\"\" onblur=\"skipcycle=false\">--------</option>";
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option onblur=\"skipcycle=false\" VALUE=\"$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";
	}
    }
    $string .= "</select>";
    $string .= "</td>";
    return $string;    
	

}

sub loadSearchGamesFabricant {
    my $category = $query->param("category");
    my $subcategory = $query->param("subcat");
    my $fabricant = $query->param("fabricant");
    my $type = $query->param("type");
    my $string .= "<td align=\"left\">$SERVER{'fabricant'}</td>";
    $string .= "<td align=\"left\"><select name=\"fabricant\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    
    if ($subcategory) {
	#code
    
    
    
    my  ($c)= $db->sqlSelectMany("DISTINCT marque",
			   "article,subcategorie_libelle_langue, libelle, langue",
			   "article.ref_categorie = 0 AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_libelle = (SELECT id_libelle FROM libelle WHERE libelle = '$subcategory')");
    
    
    my  %OPTIONS = ();

    
    if ($fabricant) {
	$string  .= "<option selected value=\"$fabricant\" onblur=\"skipcycle=false\">$fabricant</option>";
    }
    $string  .= "<option value=\"\" onblur=\"skipcycle=false\">--------</option>";
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option onblur=\"skipcycle=false\" VALUE=\"$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";
	}
    }
    $string .= "</select>";
    $string .= "</td>";
    return $string;    
	

}

sub loadSearchBoatFabricant {
    my $category = $query->param("category");
    my $subcategory = $query->param("subcat");
    my $fabricant = $query->param("fabricant");
    my $type = $query->param("type");
    my $string .= "<td align=\"left\">$SERVER{'fabricant'}</td>";
    $string .= "<td align=\"left\"><select name=\"fabricant\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    
    if ($subcategory) {
	#code
    
    
    
    my  ($c)= $db->sqlSelectMany("DISTINCT marque",
			   "article,subcategorie_libelle_langue, libelle, langue",
			   "article.ref_categorie = 94 AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_libelle = (SELECT id_libelle FROM libelle WHERE libelle = '$subcategory')");
    
    
    my  %OPTIONS = ();

    
    if ($fabricant) {
	$string  .= "<option selected value=\"$fabricant\" onblur=\"skipcycle=false\">$fabricant</option>";
    }
    $string  .= "<option value=\"\" onblur=\"skipcycle=false\">--------</option>";
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option onblur=\"skipcycle=false\" VALUE=\"$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";
	}
    }
    $string .= "</select>";
    $string .= "</td>";
    return $string;    
	

}

sub loadSearchWineFabricant {
    my $country = $query->param("country");
    my $subcategory = $query->param("subcat");
    my $fabricant = $query->param("fabricant");
    my $type = $query->param("type");
    my $string .= "<td align=\"left\">$SERVER{'fabricant'}</td>";
    $string .= "<td align=\"left\"><select name=\"fabricant\" onchange=\"go3();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    
    if ($country) {
	#code
    my ($pays_provenance ) = $db->sqlSelect("id_pays_present",  "pays_present",  "nom = '$country'");
    
    
    my  ($c)= $db->sqlSelectMany("DISTINCT marque",
			   "article,subcategorie_libelle_langue, libelle, langue",
			   "article.ref_categorie = 27 AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' AND article.ref_pays_region_vin = $pays_provenance ");
    
    
    my  %OPTIONS = ();

    
    if ($fabricant) {
	$string  .= "<option selected value=\"$fabricant\" onblur=\"skipcycle=false\">$fabricant</option>";
    }
    $string  .= "<option value=\"\" onblur=\"skipcycle=false\">--------</option>";
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option onblur=\"skipcycle=false\" VALUE=\"$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";
	}
    }
    $string .= "</select>";
    $string .= "</td>";
    return $string;    
	

}

sub loadSearchCollectionFabricant {
    my $category = $query->param("category");
    my $subcategory = $query->param("subcat");
    my $fabricant = $query->param("fabricant");
    my $type = $query->param("type");
    my $string .= "<td align=\"left\">$SERVER{'fabricant'}</td>";
    $string .= "<td align=\"left\"><select name=\"fabricant\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    
    if ($subcategory ne "") {
	#code
    
    	#print "Content-Type: text/html\n\n";
	#print "$sql";

    
    my  ($c)= $db->sqlSelectMany("DISTINCT marque",
			   "article,subcategorie_libelle_langue, libelle, langue",
			   "article.ref_categorie = 18 AND article.ref_subcategorie = subcategorie_libelle_langue.ref_subcategorie AND subcategorie_libelle_langue.ref_subcategorie = article.ref_subcategorie AND subcategorie_libelle_langue.ref_categorie = article.ref_categorie AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_libelle = (SELECT id_libelle FROM libelle WHERE libelle = '$subcategory')");
    
    
    my  %OPTIONS = ();

    
    if ($fabricant) {
	$string  .= "<option selected value=\"$fabricant\" onblur=\"skipcycle=false\">$fabricant</option>";
    }
    $string  .= "<option value=\"\" onblur=\"skipcycle=false\">--------</option>";
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option onblur=\"skipcycle=false\" VALUE=\"$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";
	}
    }
    $string .= "</select>";
    $string .= "</td>";
    return $string;    
	

}

sub loadAnimalSubCategory {
    $lang = $query->param("lang");
    loadLanguage();
    my $u = $query->param("u");
    my $category = $query->param("category");	
    my  ($c)= $db->sqlSelectMany("DISTINCT libelle.libelle","subcategorie_libelle_langue, libelle, langue","subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' AND subcategorie_libelle_langue.ref_categorie = (SELECT categorie_libelle_langue.ref_categorie FROM categorie_libelle_langue, libelle, langue WHERE libelle.libelle ='$category' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang')");
    my $selected = $query->param("subcat");
    my $string = "<select name=\"subcat\" onchange=\"go2();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {	
         $string .= "<option VALUE=\"/cgi-bin/f.pl?lang=$lang&amp;page=animal&u=$u&session=$session_id&category=$category&subcat=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select>";
    return $string;        
    
}

sub loadHabitatJardinCategory {    
    $lang = $query->param("lang");
    loadLanguage();
    my  ($c)= $db->sqlSelectMany("libelle.libelle",
			   "categorie_libelle_langue, libelle,langue",
			   "(ref_categorie = 36 OR ref_categorie = 101) AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my $selected = $query->param("category");
    my $string = "<select name=\"category\" onchange=\"go();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("category");
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {	
         $string .= "<option VALUE=\"/cgi-bin/h.pl?lang=$lang&amp;page=jardin&session=$session_id&category=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select>";
    return $string;    
    
}

sub loadHabitatJardinSubCategory {
    $lang = $query->param("lang");
    loadLanguage();
    my $category = $query->param("category");
    my $string ="";
    if ($category) {
    my  ($c)= $db->sqlSelectMany("DISTINCT libelle.libelle","subcategorie_libelle_langue, libelle, langue","subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' AND subcategorie_libelle_langue.ref_categorie = (SELECT categorie_libelle_langue.ref_categorie FROM categorie_libelle_langue, libelle, langue WHERE libelle.libelle ='$category' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang')");
    my $selected = $query->param("subcat");
    $string = "<select name=\"subcat\" onchange=\"go2();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("category");
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {	
         $string .= "<option VALUE=\"/cgi-bin/h.pl?lang=$lang&amp;page=jardin&session=$session_id&category=$category&subcat=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select>";
    }
    return $string;        
}

sub loadSearchArtCategory {
    my  ($c)= $db->sqlSelectMany("libelle.libelle",
			   "categorie_libelle_langue, langue, libelle",
			   "categorie_libelle_langue.ref_categorie = 0 AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND langue.id_langue = langue.id_langue AND langue.key = '$lang'");
    my $selected = $query->param("category");
    my $string = "$LABEL{'category'}<td>$SERVER{'category'}</td><td><select name=\"category\" onchange=\"go();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("departement");
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option VALUE=\"/cgi-bin/a.pl?lang=$lang&amp;page=art_design&session=$session_id&category=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select></td></tr>";
    return $string;    	    
}

sub loadSearchAnimalCategory {
    my  ($c)= sqlSelectMany("libelle.libelle",
			   "categorie_libelle_langue, libelle, langue",
			   "categorie_libelle_langue.ref_categorie BETWEEN 66 AND 68 AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'" );
    my $selected = $query->param("category");
    my $string = "<tr><td>$SERVER{'category'}</td><td><select name=\"category\" onchange=\"go6();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("departement");
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();    
    while(($OPTIONS{'category'})=$c->fetchrow()) {	
         $string .= "<option VALUE=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=animal&session=$session_id&category=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select></td>";
    return $string;    	 
}

sub loadSearchAnimalSubCategory {
    my $category = $query->param("category");
    my  ($c)= sqlSelectMany("nom",
			   "subcategorie_libelle_langue, libelle, langue",
			   "subcategorie.ref_categorie = (SELECT categorie_libelle_langue.id_categorie FROM categorie_libelle_langue, libelle, langue WHERE libelle.libelle  = '$category' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.id_langue = langue.id_langue AND langue.key = '$lang')");
    my $selected = $query->param("subcat");
    my $string = "<td>$SERVER{'subcat'}</td><td><select name=\"subcat\" onchange=\"go7();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option VALUE=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=animal&session=$session_id&subcat=$OPTIONS{'category'}&category=$category\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select></td>";
    return $string;    	    
}



sub loadSearchCollectionSubCategory {
    my $category = $query->param("subcategory");
    my  ($c)= sqlSelectMany("nom",
			   "subcategorie_libelle_langue, libelle, langue",
			   "subcategorie_libelle_langue.ref_categorie = (SELECT id_categorie FROM categorie_libelle_langue, libelle, langue WHERE libelle.libelle  = '$category' AND categorie_libelle_langue.ref_libelle = libelle.libelle AMD categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang') AND subcategorie_libelle_langue.ref_categorie = categorie_libelle_langue.id_categorie = categorie.id_categorie AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my $selected = $query->param("subcat");
    my $string = "$SERVER{'subcat'}<select name=\"subcategory\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {	
         $string .= "<option VALUE=\"$OPTIONS{'category'}\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select></td>";
    return $string;    	    
}

sub loadSearchInstrumentsSubCategory {
    my $category = $query->param("category");
    my ($a) = $db->sqlSelect("ref_categorie","categorie_libelle_langue, langue, libelle","libelle.libelle = '$category' and categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my  ($c);
    my $selected = $query->param("subcategory");
    my $string = "<select name=\"subcategory\" onchange=\"go4();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("category");
    $string  .= "<option selected value=\"$selected\">$selected</option>";
    $string  .= "<option value=\"\">--------</option>";

    if ($a) {
	my  ($c)= $db->sqlSelectMany("libelle.libelle","subcategorie_libelle_langue, libelle, langue","subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle and subcategorie_libelle_langue.ref_categorie = $a");
        my  %OPTIONS = ();    
        while(($OPTIONS{'category'})=$c->fetchrow()) {	
             $string .= "<option VALUE=\"/cgi-bin/m.pl?lang=$lang&amp;page=intruments&show_popup=true&session=$session_id&category=$category&subcategory=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>" ;
	}
    }    
    $string .= "</select>";
    return $string;
}

sub loadSearchInstrumentsCategory {
    my $category = $query->param("category");
    $lang = $query->param("lang");
    loadLanguage();
    my  ($c)= $db->sqlSelectMany("libelle.libelle",
			   "categorie_libelle_langue, libelle,langue",
			   "(ref_categorie = 92  or ref_categorie = 93) AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my $selected = $query->param("category");
    my $string = "<td>$SERVER{'category'}</td><td><select name=\"category\" onchange=\"go3();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();    
    while(($OPTIONS{'category'})=$c->fetchrow()) {	
         $string .= "<option VALUE=\"/cgi-bin/m.pl?lang=$lang&amp;page=intruments&show_popup=true&session=$session_id&category=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select></td>";
    return $string;    	    
}

sub loadSearchInstrumentsFabricant {
    my $category = $query->param("category");
    my $subcategory = $query->param("subcat");
    my $fabricant = $query->param("fabricant");
    my $type = $query->param("type");
    $lang = $query->param("lang");
    loadLanguage();
    
    my  ($c)= $db->sqlSelectMany("DISTINCT marque",
			   "article,subcategorie_libelle_langue, libelle, langue",
			   "subcategorie_libelle_langue.ref_categorie = (select ref_categorie from article, categorie_libelle_langue, libelle, langue where libelle.libelle = '$category' AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle) AND subcategorie_ref_libelle = (SELECT id_libelle FROM libelle WHERE libelle = '$subcategory')");
    
    my $string .= "<td align=\"left\">$SERVER{'fabricant'}</td>";
    $string .= "<td align=\"left\"><select name=\"fabricant\" onchange=\"go3();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    
    my  %OPTIONS = ();

    
    if ($fabricant) {
	$string  .= "<option selected value=\"$fabricant\" onblur=\"skipcycle=false\">$fabricant</option>";
    }
    $string  .= "<option value=\"\" onblur=\"skipcycle=false\">--------</option>";
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option onblur=\"skipcycle=false\" VALUE=\"/cgi-bin/m.pl?lang=$lang&amp;page=search_baby&session=$session_id&fabricant=$OPTIONS{'category'}&type=$type&category=$category\">$OPTIONS{'category'}</option>";
	}
    $string .= "</select>";
    $string .= "</td>";
    return $string;    
	
}


sub loadSearchJardinCategory {
    $lang = $query->param("lang");
    loadLanguage();
    my  ($c)= $db->sqlSelectMany("libelle.libelle",
			   "categorie_libelle_langue, langue, libelle",
			   "ref_categorie = 36 AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my $selected = $query->param("category");
    my $string = "<tr><td>$SERVER{'category'}</td><td><select name=\"category\" onchange=\"go3();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("departement");
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option VALUE=\"/cgi-bin/h.pl?lang=$lang&amp;page=jardin&session=$session_id&category=$OPTIONS{'category'}&show_popup=true\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select></td>";
    return $string;    	    
}
sub loadSearchJardinSubCategory {
    $lang = $query->param("lang");
    loadLanguage();
    my $category = $query->param("category");
    my  ($c)= $db->sqlSelectMany("libelle.libelle",
			   "subcategorie_libelle_langue, libelle, langue",
			   "subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' AND ref_categorie = (SELECT ref_categorie FROM categorie_libelle_langue, libelle, langue WHERE libelle.libelle  = '$category' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND langue.key = '$lang' AND categorie_libelle_langue.ref_langue = langue.id_langue)");
    my $selected = $query->param("subcategory");
    my $string = "<td>$SERVER{'subcat'}</td><td><select name=\"subcategory\" onchange=\"go4();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option VALUE=\"/cgi-bin/h.pl?lang=$lang&amp;page=jardin&session=$session_id&subcategory=$OPTIONS{'category'}&category=$category&show_popup=true\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select></td>";
    return $string;    	    
}

sub loadSearchCalendarCategory {
    my $category = $query->param("category");
    my  ($c)= sqlSelectMany("libelle.libelle","categorie_libelle_langue, libelle, langue","ref_categorie = 57 OR ref_categorie = 79 AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND libelle.categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my $selected = $query->param("category");
    my $string = "<tr><td>$SERVER{'category'}</td><td><select name=\"category\" onchange=\"go();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("departement");
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option VALUE=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=search_calendar&session=$session_id&category=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select></td>";
    return $string;    	    
}

sub loadSearchCalendarSubCategory {
    my $category = $query->param("category");
    my $subcat= $query->param("subcat");
    my  ($c)= sqlSelectMany("libelle.libelle",
			   "subcategorie_libelle_langue, libelle, langue",
			   "ref_categorie = (SELECT id_categorie FROM categorie_libelle_langue, libelle WHERE libelle.libelle = '$category' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle) AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my $selected = $query->param("subcat");
    my $string = "<tr><td>$SERVER{'category'}</td><td><select name=\"subcat\" onchange=\"go2();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("departement");
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option VALUE=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=search_calendar&session=$session_id&category=$category&subcat=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select></td>";
    return $string;    	    
}
sub loadSearchBabyCategoryTOREMOVE {
    my  ($c)= sqlSelectMany("libelle.libelle",
			   "categorie_libelle_langue, libelle, langue",
			   "id_categorie BETWEEN 58 AND 59 AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my $selected = $query->param("category");
    my $string = "<tr><td>$SERVER{'category'}</td><td><select name=\"category\" onchange=\"go();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("departement");
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option VALUE=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=search_baby&session=$session_id&category=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";
	}
    $string .= "</select></td>";
    return $string;    	    
}

sub loadSearchBabySubCategoryTOREMOVE {
    my $category = $query->param("category");
    my $subcat = $query->param("subcat");
    my  ($c)= sqlSelectMany("libelle.libelle",
			   "subcategorie_libelle_langue,libelle",
			   "ref_categorie = (SELECT id_categorie FROM categorie_libelle_langue, libelle WHERE nom  = '$category' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle) AND subcategorie.ref_subcategorie= subcategorie_libelle_langue.ref_subcactegorie = (SELECT libelle.libelle FROM subcategorie_libelle_langue, libelle, langue WHERE libelle.libelle = '$subcat' AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')");
    my $selected = $query->param("subcat");
    my $string = "<td>$SERVER{'subcat'}</td><td><select name=\"subcat\" onchange=\"go2();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option VALUE=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=search_baby&session=$session_id&subcat=$OPTIONS{'category'}&category=$category\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select></td>";
    return $string;    	    
}

sub loadSearchBabyFabricant {
    my $category = $query->param("category");
    my $subcategory = $query->param("subcategory");
    my $fabricant = $query->param("fabricant");
    my $type = $query->param("type");
    my $string .= "<td align=\"left\">$SERVER{'fabricant'}</td>";
    $string .= "<td align=\"left\"><select name=\"fabricant\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    
    if ($subcategory) {
	#code
    
    
    
    my  ($c)= $db->sqlSelectMany("DISTINCT marque",
			   "article,subcategorie_libelle_langue, libelle, langue",
			   "article.ref_categorie = subcategorie_libelle_langue.ref_categorie AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_libelle = (SELECT id_libelle FROM libelle WHERE libelle = '$subcategory')");
    
    
    my  %OPTIONS = ();

    
    if ($fabricant) {
	$string  .= "<option selected value=\"$fabricant\" onblur=\"skipcycle=false\">$fabricant</option>";
    }
    $string  .= "<option value=\"\" onblur=\"skipcycle=false\">--------</option>";
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option onblur=\"skipcycle=false\" VALUE=\"$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";
	}
    }
    $string .= "</select>";
    $string .= "</td>";
    return $string;    
	

}

sub loadSearchLingerieCategory {
    $lang = $query->param("lang");
    my $subcat = $query->param("subcat");
    loadLanguage();
    my  ($c)= $db->sqlSelectMany("libelle.libelle",
			   "categorie_libelle_langue,libelle, langue",
			   "(categorie_libelle_langue.ref_categorie = 21 or categorie_libelle_langue.ref_categorie = 31) AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my $selected = $query->param("category");
    my $string = "<tr><td>$SERVER{'category'}</td><td><select name=\"category\" onchange=\"go3();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("departement");
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option VALUE=\"/cgi-bin/d.pl?lang=$lang&amp;page=lingerie&session=$session_id&category=$OPTIONS{'category'}&subcat=$subcat&show_popup=true\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select></td>";
    return $string;    	    
}

sub loadSearchLingerieSubCategory {
    my $string;
    $lang = $query->param("lang");
    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");	
    my $category = $query->param("category");
    my $subcategory = $query->param("subcategory");
    my $fabricant = $query->param("fabricant");
    $string = "<select name=\"subcategory\" onchange=\"go4();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    if ($category) {
	my  ($c)= $db->sqlSelectMany("libelle.libelle",
			       "subcategorie_libelle_langue, libelle,langue",
			       "subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' AND subcategorie_libelle_langue.ref_categorie = (SELECT ref_categorie FROM categorie_libelle_langue, libelle, langue WHERE libelle.libelle = '$category' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')");
	 
	if ($subcategory) {
		$string  .= "<option selected value=\"$subcategory\" onblur=\"skipcycle=false\">$subcategory</option>";
	}
    
	my  %OPTIONS = ();
	$string  .= "<option value=\"\" onblur=\"skipcycle=false\">--------</option>";
     
       while(($OPTIONS{'category'})=$c->fetchrow()) {
	
	 $string .= "<option onblur=\"skipcycle=false\" VALUE=\"/cgi-bin/d.pl?lang=$lang&page=lingerie&fabricant=$fabricant&session=$session_id&subcategory=$OPTIONS{'category'}&category=$category&country_swiss=$country_swiss&country_france=$country_france&with_lang_french=$with_lang_french&with_lang_italian=$with_lang_italian&with_lang_german=$with_lang_german&with_lang_english=$with_lang_english&subcategory=$subcategory&fabricant=$fabricant&show_popup=true\">$OPTIONS{'category'}</option>";
	}
    }
  $string .= "</select>";
  return $string;       	
}

sub loadSearchLingerieFabricant {
    $lang = $query->param("lang");
    my $category = $query->param("category");
    my $subcategory = $query->param("subcategory");
    my $fabricant = $query->param("fabricant");
    my $type = $query->param("type");
    loadLanguage();
    my  ($c)= $db->sqlSelectMany("DISTINCT marque",
			   "article,subcategorie_libelle_langue",
			   "article.ref_subcategorie = (select ref_subcategorie from subcategorie_libelle_langue, libelle WHERE libelle.libelle = '$subcategory' AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle) AND article.ref_categorie = (select ref_categorie from categorie_libelle_langue, libelle,langue where libelle.libelle = '$category' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')");
    
    my $string .= "<td align=\"left\">$SERVER{'fabricant'}</td>";
    $string .= "<td align=\"left\"><select name=\"fabricant\"  onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    
    my  %OPTIONS = ();

    
    if ($fabricant) {
	$string  .= "<option selected value=\"$fabricant\" onblur=\"skipcycle=false\">$fabricant</option>";
    }
    $string  .= "<option value=\"\" onblur=\"skipcycle=false\">--------</option>";
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option onblur=\"skipcycle=false\" VALUE=\"$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";
	}
    $string .= "</select>";
    $string .= "</td>";
    return $string;    
	
}

sub loadSearchParfumCategory {
    loadLanguage();
    $lang = $query->param("lang");
    my $subcategory = $query->param("subcategory");
    my $fabricant = $query->param("fabricant");
    my  ($c)= $db->sqlSelectMany("libelle.libelle",
			   "categorie_libelle_langue, libelle,langue",
			   "(ref_categorie = 13 OR ref_categorie = 16) AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my $selected = $query->param("category");
    my $string = "<tr><td>$SERVER{'category'}</td><td><select required name=\"category\" onchange=\"go();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("departement");
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option VALUE=\"/cgi-bin/b.pl?lang=$lang&amp;page=parfum&session=$session_id&category=$OPTIONS{'category'}&subcategory=$subcategory&fabricant=$fabricant&show_popup=true\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select></td>";
    return $string;    	    
}
sub loadSearchParfumSubCategory {
    my $category = $query->param("category");
    my $subcategory = $query->param("subcategory");
    my $fabricant = $query->param("fabricant");
    my  ($c)= $db->sqlSelectMany("libelle.libelle",
			   "subcategorie_libelle_langue, libelle, langue",,
			   "subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' AND ref_categorie = (SELECT ref_categorie FROM categorie_libelle_langue, libelle WHERE libelle.libelle  = '$category' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')");
    my $selected = $query->param("subcategory");
    my $string = "<td>$SERVER{'subcat'}</td><td><select required name=\"subcategory\" onchange=\"go2();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option VALUE=\"/cgi-bin/b.pl?lang=$lang&amp;page=parfum&session=$session_id&subcategory=$OPTIONS{'category'}&category=$category&fabricant=$fabricant&show_popup=true\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select></td>";
    return $string;    	    
}

sub loadSearchParfumValeur {
    my $string;
    $string .= "<td>";
    $string .= "<td align=\"left\">$SERVER{'valeur'}</td><td align=\"left\"><input type=\"text\" name=\"valeur\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td>";    
    $string .= "</td>";    
    return $string;
}

sub loadSearchParfumFabricant {
    my $category = $query->param("category");
    my $subcategory = $query->param("subcategory");
    my $fabricant = $query->param("fabricant");
    my $type = $query->param("type");
    
    my $string .= "<td align=\"left\">$SERVER{'fabricant'}</td>";
    $string .= "<td align=\"left\"><select name=\"fabricant\"  onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    
    my  %OPTIONS = ();

    
    if ($fabricant) {
	$string  .= "<option selected value=\"$fabricant\" onblur=\"skipcycle=false\">$fabricant</option>";
    }
    $string  .= "<option value=\"\" onblur=\"skipcycle=false\">--------</option>";
 
    if ($subcategory) {
	#code

    
    my  ($c)= $db->sqlSelectMany("DISTINCT marque",
			   "article,subcategorie_libelle_langue, libelle, langue",
			   "article.ref_subcategorie = (select ref_subcategorie from subcategorie_libelle_langue, libelle WHERE libelle.libelle = '$subcategory' AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang') AND article.ref_categorie = '13'");
    
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option onblur=\"skipcycle=false\" VALUE=\"$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";
	}
    }
    $string .= "</select>";
    $string .= "</td>";
    return $string;    
	
}
sub loadSearchBabyCategory {
    $lang = $query->param("lang");
    loadLanguage();
    my  ($c)= $db->sqlSelectMany("libelle.libelle",
			    "libelle, categorie_libelle_langue,langue",
			   "ref_categorie = 23 and categorie_libelle_langue.ref_libelle = libelle.id_libelle and categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
    my $selected = $query->param("category");
    my $string = "<td>$SERVER{'category'}</td><td><select name=\"category\" onchange=\"go3();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";

    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option VALUE=\"/cgi-bin/e.pl?lang=$lang&amp;page=baby&session=$session_id&category=$OPTIONS{'category'}&show_popup=true\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select></td>";
    return $string;    	
}  


sub loadSearchBabySubCategory {
    $lang = $query->param("lang");
    loadLanguage();
    my $category = $query->param("category");
    my $subcategory = $query->param("subcategory");
    my $fabricant = $query->param("fabricant");
    my  ($c)= $db->sqlSelectMany("libelle.libelle",
			    "libelle, subcategorie_libelle_langue,langue",
			   "ref_categorie = 23 and subcategorie_libelle_langue.ref_libelle = libelle.id_libelle and subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
    my $selected = $query->param("subcategory");
    my $string = "<td>$SERVER{'subcategory'}</td><td><select name=\"subcategory\" onchange=\"go4();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";

    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option VALUE=\"/cgi-bin/e.pl?lang=$lang&amp;page=baby&session=$session_id&category=$category&subcategory=$OPTIONS{'category'}&fabricant=$fabricant&show_popup=true\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select></td>";
    return $string;    	
}
sub loadSearchImmoCountry {

    my  ($c)= $db->sqlSelectMany("nom",
			   "pays_present",
			   "id_pays_present = id_pays_present");
    my $selected = $query->param("country");
    my $string = "<select name=\"country\" onchange=\"go6();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("departement");
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option VALUE=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=immo&session=$session_id&country=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select>";
    return $string;    	
}

sub loadImmobilierType {
    my $canton = $query->param("canton");
    my $country = $query->param("country");    
    my $immo_type = $query->param("immo_type");
    my $location_type = $query->param("location_type");
    my $departement = $query->param("departement");
    my  $string .= "";
    
    my  ($c)= sqlSelectMany("libelle.libelle","subcategorie_libelle_langue,categorie_libelle_langue, libelle, langue","subcategorie_libelle_langue.ref_categorie = categorie.id_categorie and subcategorie_libelle_langue.ref_categorie = '11' AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND langue.key = '$lang'");
    my  %OPTIONS = ();
    
    
    $string .= "<select name=\"immo_type\" onchange=\"go4();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";

    if ($immo_type) {
	$string  .= "<option selected value=\"$immo_type\">$immo_type</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    while( ($ARTICLE{'genre'})=$c->fetchrow()) {
	         $string .= "<option VALUE=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=search_immo&session=$session_id&country=$country&canton=$canton&departement=$departement&location_type=$location_type&immo_type=$ARTICLE{'genre'}\">$ARTICLE{'genre'}</option>";
    }
    $string .= "</select>";
    return $string;
}

sub loadSearchImmoCanton {
    my $canton = $query->param("canton");
    my $country = $query->param("country");    
    my $immo_type = $query->param("immo_type");
    my $location_type = $query->param("location_type");
    my $departement = $query->param("departement");

    my  ($c)= $db->sqlSelectMany("nom",
			   "canton_$lang",
			   "id_canton = id_canton");
    #my $selected = $query->param("country");
    my $string = "<select name=\"canton\" onchange=\"go3();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    if ($canton) {
	$string  .= "<option selected value=\"$canton\">$canton</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    #$string  .= "<option selected value=\"$selected\">$selected</option>";
    my  %OPTIONS = ();
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option VALUE=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=search_immo&session=$session_id&canton=$OPTIONS{'category'}&country=$country&immo_type=$immo_type&departement=$departement&location_type=$location_type\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select>";
    return $string;    
	
}
sub loadRegisterCanton {
    my $canton = $query->param("canton");
    my $country = $query->param("country");    
    my $departement = $query->param("departement");

    my  ($c)= $db->sqlSelectMany("nom",
			   "canton_$lang",
			   "id_canton = id_canton");
    #my $selected = $query->param("country");
    if ($canton) {
	$string  .= "<option selected value=\"$canton\">$canton</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    #$string  .= "<option selected value=\"$selected\">$selected</option>";
    my  %OPTIONS = ();
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option VALUE=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=register&session=$session_id&canton=$OPTIONS{'category'}&country=$country&immo_type=$immo_type&departement=$departement&location_type=$location_type\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select>";
    return $string;    
	
}

sub loadSearchWatchSubCategory {
    my $category = $query->param("category");
    $lang = $query->param("lang");
    loadLanguage();
    my $string = "<td>$SERVER{'subcategory'}</td><td><select name=\"subcat\" onchange=\"go4();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
  
    if ($category) {
	#code
    
    my ($ref_category) = $db->sqlSelect("ref_categorie","categorie_libelle_langue,libelle,langue","libelle.libelle = '$category' and categorie_libelle_langue.ref_libelle = libelle.id_libelle and categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
    my  ($c)= $db->sqlSelectMany("libelle.libelle",
			   "subcategorie_libelle_langue, langue, libelle",
			   "ref_categorie = $ref_category AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND ref_categorie = $ref_category");
    my $selected = $query->param("subcategory");
    my $departement = $query->param("departement");
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option VALUE=\"/cgi-bin/g.pl?lang=$lang&amp;page=watch&session=$session_id&subcategory=$OPTIONS{'category'}&category=$category&show_popup=true\">$OPTIONS{'category'}</option>" ;
	}
    }
    $string .= "</select></td>";
    return $string;    
	
}



sub loadSearchWatchCategory {
    $lang = $query->param("lang");
    loadLanguage();
    my $category = $query->param("category");
    my $subcategory = $query->param("subcategory");
    my $fabricant = $query->param("fabricant");
    my  ($c)= $db->sqlSelectMany("libelle.libelle",
			   "categorie_libelle_langue, libelle, langue",
			   "ref_categorie BETWEEN 34 AND  35 AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my $selected = $query->param("category");
    my $string = "<td>$SERVER{'category'}</td><td><select name=\"category\" onchange=\"go3();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("departement");
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option VALUE=\"/cgi-bin/g.pl?lang=$lang&amp;page=watch&session=$session_id&category=$OPTIONS{'category'}&subcategory=$subcategory&fabricant=$fabricant&show_popup=true\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select></td>";
    return $string;    
	
}



sub loadSearchCigaresFabricant {
    my $category = $query->param("category");
    my $fabricant = $query->param("fabricant");
    my $type = $query->param("type");
    
    my  ($c)= sqlSelectMany("DISTINCT marque",
			   "article,subcategorie_libelle_langue",
			   "ref_subcategorie = (select ref_subcategorie from subcategorie_libelle_langue, libelle, langue where libelle.libelle = '$category' AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')");
    
    my $string .= "<td align=\"left\">$SERVER{'fabricant'}</td>";
    $string .= "<td align=\"left\"><select name=\"fabricant\" onchange=\"go2();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    
    my  %OPTIONS = ();

    
    if ($fabricant) {
	$string  .= "<option selected value=\"$fabricant\" onblur=\"skipcycle=false\">$fabricant</option>";
    }
    $string  .= "<option value=\"\" onblur=\"skipcycle=false\">--------</option>";
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option onblur=\"skipcycle=false\" VALUE=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=search_cigares&session=$session_id&fabricant=$OPTIONS{'category'}&type=$type&category=$category\">$OPTIONS{'category'}</option>";
	}
    $string .= "</select>";
    $string .= "</td>";
    return $string;    
	
}



sub loadSearchBabyFabricantTOREMOVE {
    my $category = $query->param("category");
    my $fabricant = $query->param("fabricant");
    my $subcategory = $query->param("subcategory");
    my $type = $query->param("type");
    
    my  ($c)= $db->sqlSelectMany("DISTINCT marque",
			   "article,subcategorie_libelle_langue",
			   "article.ref_subcategorie = (select ref_subcategorie from subcategorie_libelle_langue, libelle, langue where libelle.libelle = '$subcategory' AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')");
    
    my $string .= "<td align=\"left\">$SERVER{'fabricant'}</td>";
    $string .= "<td align=\"left\"><select name=\"fabricant\" onchange=\"go3();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    
    my  %OPTIONS = ();

    
    if ($fabricant) {
	$string  .= "<option selected value=\"$fabricant\" onblur=\"skipcycle=false\">$fabricant</option>";
    }
    $string  .= "<option value=\"\" onblur=\"skipcycle=false\">--------</option>";
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option onblur=\"skipcycle=false\" VALUE=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=search_baby&session=$session_id&fabricant=$OPTIONS{'category'}&category=$category&subcategory=$subcategory\">$OPTIONS{'category'}</option>";
	}
    $string .= "</select>";
    $string .= "</td>";
    return $string;    
}

sub loadSearchWatchProperties {
 my $string;
 $string .= "<tr>";
 $string .= "<td align=\"left\">$SERVER{'price_min'}</td><td align=\"left\"><input type=\"text\" name=\"valeur\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td>";
 $string .= "</tr>";
 $string .= "<tr>";
 $string .= "<td align=\"left\">$SERVER{'price_min'}</td><td align=\"left\"><input type=\"text\" name=\"price_min\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td><td align=\"left\">$SERVER{'price_max'}</td><td align=\"left\"><input type=\"text\" name=\"price_max\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td>";
 $string .= "</tr>";
}


sub loadSearchCigaresProperties {
	my $string;
	$string .= "<tr>";
	$string .= "<td align=\"left\">$SERVER{'price_min'}</td><td align=\"left\"><input type=\"text\" name=\"price_min\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td><td align=\"left\">$SERVER{'price_max'}</td><td align=\"left\"><input type=\"text\" name=\"price_max\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td>";
	$string .= "</tr>";

	return $string;
}

sub loadSearchBoatCategories {
    my  ($c)= sqlSelectMany("libelle.libelle",
			   "subcategorie_libelle_langue,libelle, langue",
			   "ref_categorie = 19 AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle  AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
        
    my $categorie = $query->param("category");
    my $string;
    my  %OPTIONS = ();
    $string .= "<td align=\"left\">$SERVER{'category'}</td>";
    $string .= "<td align=\"left\"><select name=\"category\" onchange=\"go();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    if ($categorie) {
	$string  .= "<option selected value=\"$categorie\" onblur=\"skipcycle=false\">$categorie</option>";
    }
    $string  .= "<option value=\"\">--------</option>";            
    while(($OPTIONS{'category'})=$c->fetchrow()) {
         $string .= "<option value=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=search_boat&session=$session_id&category=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";
	}    
    return $string;    	
}

sub loadSearchGamesMenu {
    $lang = $query->param("lang");
    loadLanguage();
    my  ($c)= $db->sqlSelectMany("libelle.libelle","categorie_libelle_langue, libelle, langue","(categorie_libelle_langue.ref_categorie = 11 or categorie_libelle_langue.ref_categorie = 95 )and categorie_libelle_langue.ref_libelle = libelle.id_libelle and categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'	");
    my $selected = $query->param("category");
    my $string = "<td>$SERVER{'category'}</td><td><select name=\"category\" onchange=\"go3();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("departement");
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option VALUE=\"/cgi-bin/r.pl?lang=$lang&amp;page=games&show_popup=true&session=$session_id&category=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select></td>";
    return $string;    
}

sub loadSearchGamesSubMenu {
    $lang = $query->param("lang");
    loadLanguage();
    my $category = $query->param("category");
    my  ($c)= $db->sqlSelectMany("libelle.libelle",
			   " subcategorie_libelle_langue, libelle, langue",
			   " subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' AND subcategorie_libelle_langue.ref_categorie  = (SELECT ref_categorie FROM categorie_libelle_langue, langue, libelle WHERE libelle.libelle ='$category' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue)");
    my $selected = $query->param("subcategory");
    my $string = "<td>$SERVER{'subcategory'}</td><td><select name=\"subcat\" onchange=\"go4();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("departement");
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option VALUE=\"/cgi-bin/r.pl?lang=$lang&amp;page=games&session=$session_id&show_popup=true&category=$category&subcategory=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select></td>";
    return $string;    
	
}
sub loadSearchGamesType {
    my $category = $query->param("category");
    my $subcat = $query->param("subcat");
    my  ($c)= sqlSelectMany("libelle.libelle",
			   "type_de_jeux_libelle_langue, langue, libelle",
			   "type_de_jeux_libelle_langue.ref_libelle = libelle.id_libelle AND type_de_jeux_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my $selected = $query->param("game_type");
    my $string = "<td>$SERVER{'game_type'}</td><td><select name=\"game_type\" onchange=\"go3();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option VALUE=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=search_games&session=$session_id&category=$category&subcat=$subcat&game_type=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select></td>";
    return $string;    
	
}

sub loadEditor {
	my $string;
	$string .= "<tr><td>Editeur</td><td><input type=\"text\" name=\"editor\"></td>";
	$string .= "</tr>";
}

sub loadSearchGamesUsed {
	my $string;
	$string .= "<tr><td>$SERVER{'used'}</td><td>";
	my  ($c)= sqlSelectMany("libelle.libelle","etat_libelle_langue, langue, libelle", "etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' AND etat_libelle_langue.ref_libelle = libelle.id_libelle");
	$string .= "<select name=\"used\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\" >";
	my  %OPTIONS = ();
	while(($OPTIONS{'category'})=$c->fetchrow()) {$string .= "<option value=\"$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";}
	$string .= "</select></td></tr>";
	return $string;	
}
sub getUserID {
    my $user= shift || '';
    my $user_id;
    if ($user ne '') {
	$user_id = sqlSelect ("id_personne", "personne","nom_utilisateur= '$user_id'")
    }
    return $user_id;
}
sub loadSearchJardinUsed {
	my $string;
	$string .= "<tr><td>$SERVER{'used'}</td><td>";
	my  ($c)= sqlSelectMany("libelle.libelle","etat_libelle_langue, langue, libelle", "etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' AND etat_libelle_langue.ref_libelle = libelle.id_libelle");
	$string .= "<select name=\"used\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\" >";
	my  %OPTIONS = ();
	while(($OPTIONS{'category'})=$c->fetchrow()) {$string .= "<option value=\"$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";}
	$string .= "</select></td></tr>";
	return $string;	
}

sub loadSearchDvdCategories {
    my  ($c)= $db->sqlSelectMany("libelle.libelle","subcategorie_libelle_langue, libelle, langue", "ref_categorie = 38 AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my $selected = $query->param("subcategory");
    my $string = "<select name=\"subcategory\"  onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("departement");
    if ($selected) {$string  .= "<option selected value=\"$selected\">$selected</option>";}
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    while(($OPTIONS{'category'})=$c->fetchrow()) {$string .= "<option VALUE=\"$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";}
    $string .= "</select>";
    return $string;    
	
}
sub loadSearchDvdProperties {
	my $string;
	$string .= "<tr><td>$SERVER{'actor'}</td><td><input type=\"text\" name=\"actor\" value=\"\"></td></tr>";
	$string .= "<tr><td>$SERVER{'realisator'}</td><td><input type=\"text\" name=\"realisator\" value=\"\"></td></tr>";
	$string .= "<tr><td>$SERVER{'year'}</td><td><input type=\"text\" name=\"year\" value=\"\"></td></tr>";
	return $string;
}

sub loadSearchSportMenu {
    my  ($c)= $db->sqlSelectMany("libelle.libelle","categorie_libelle_langue, libelle, langue","ref_categorie between 96 and 99 AND categorie_libelle_langue.ref_langue = langue.id_langue AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND langue.key = '$lang' ");
    my $selected = $query->param("category");
    my $string = "<select name=\"category\" onchange=\"go3();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("departement");
    if ($selected) {$string  .= "<option selected value=\"$selected\">$selected</option>";}
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	$string .= "<option VALUE=\"/cgi-bin/u.pl?lang=$lang&amp;page=sport&show_popup=true&amp;session=$session_id&category=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";}
    $string .= "</select>";
    return $string;    
}

sub loadSearchSportSubMenu {
    my $category = $query->param("category");
    my  ($c)= $db->sqlSelectMany("libelle.libelle","subcategorie_libelle_langue,categorie_libelle_langue, langue, libelle","subcategorie_libelle_langue.ref_categorie = categorie_libelle_langue.ref_categorie AND categorie_libelle_langue.ref_categorie  = (SELECT ref_categorie FROM categorie_libelle_langue, libelle, langue WHERE libelle.libelle = '$category' AND categorie_libelle_langue.ref_libelle =  libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang') AND subcategorie_libelle_langue.ref_libelle =  libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my $selected = $query->param("subcat");
    my $string = "<select name=\"subcat\" onchange=\"go2();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("departement");
    if ($selected) {$string  .= "<option selected value=\"$selected\">$selected</option>";}
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();    
    while(($OPTIONS{'category'})=$c->fetchrow()) {$string .= "<option VALUE=\"$OPTIONS{'category'}\">$OPTIONS{'category'}</option>" ;}
    $string .= "</select>";
    return $string;    
	
}
sub loadSearchSportProperties {
	my $string;
	$string .= "<tr><td>$SERVER{'price_min'}</td><td><input type=\"text\" name=\"price_min\"></td><td>$SERVER{'price_max'}</td><td><input type=\"text\" name=\"price_max\"></td>";$string .= "</tr>";
	return $string;
}                                                                                                                                                              
sub loadSportMenu {
    $lang = $query->param("lang");	
    my  ($c)= $db->sqlSelectMany("libelle.libelle","categorie_libelle_langue, libelle, langue","categorie_libelle_langue.ref_categorie between 96 and 99 AND categorie_libelle_langue.ref_langue = langue.id_langue AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND langue.key = '$lang' ");
    my $selected = $query->param("category");
    my $string = "<select name=\"category\" onchange=\"go();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("departement");
    if ($selected) {$string  .= "<option selected value=\"$selected\">$selected</option>";}
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();    
    while(($OPTIONS{'category'})=$c->fetchrow()) {$string .= "<option VALUE=\"/cgi-bin/u.pl?lang=$lang&amp;page=sport&amp;session=$session_id&category=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";}
    $string .= "</select>";
    return $string;   
}

sub loadSportSubMenu {
    $lang = $query->param("lang");	    
    my $category = $query->param("category");
    my ($ref_categorie) = $db->sqlSelect("ref_categorie", "categorie_libelle_langue,libelle,langue", "libelle.libelle = '$category' and categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my $selected = $query->param("subcat");
    my $string = "<select name=\"subcat\" onchange=\"go2();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("departement");
    if ($selected) {$string  .= "<option selected value=\"$selected\">$selected</option>";}
    $string  .= "<option value=\"\">--------</option>";

    if ($ref_categorie) {
	my  ($c)= $db->sqlSelectMany(" DISTINCT libelle.libelle","subcategorie_libelle_langue,libelle, langue, categorie_libelle_langue", "subcategorie_libelle_langue.ref_categorie = $ref_categorie and subcategorie_libelle_langue.ref_libelle = libelle.id_libelle and subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	my  %OPTIONS = ();    
	while(($OPTIONS{'category'})=$c->fetchrow()) {$string .= "<option VALUE=\"/cgi-bin/u.pl?lang=$lang&amp;page=sport&amp;session=$session_id&category=$category&subcat=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";}
	
    }
  $string .= "</select>";  
    return $string;    
	
}

sub getArtAndDesignCategory {
    my $category = $query->param("category");
    my  ($c)= sqlSelectMany("libelle.libelle","categorie_libelle_langue, libelle, langue","ref_categorie = 35 or ref_categorie = 36 AND categorie_libelle_langue.ref_libelle = libelle.libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my $selected = $query->param("category");
    my $string = "<select name=\"category\" onchange=\"go();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("departement");
    if ($selected) {$string  .= "<option selected value=\"$selected\">$selected</option>";}
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {$string .= "<option VALUE=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=art_design&amp;session=$session_id&category=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>" ;}
    $string .= "</select>";
    return $string;    
	
}
sub getArtAndDesignSubCategory {
    my $category = $query->param("category");
    my  ($c)= sqlSelectMany("libelle.libelle","categorie_libelle_langue,subcategorie_libelle_langue","subcategorie_libelle_langue.ref_categorie = categorie_libelle_langue.ref_categorie = (SELECT categorie_libelle_langue_ref_categorie FROM categorie_libelle_langue, libelle, langue WHERE libelle.libelle = '$category' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')");
    my $selected = $query->param("subcat");
    my $string = "<select name=\"subcat\" onchange=\"go2();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("departement");
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {$string .= "<option VALUE=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=art_design&amp;session=$session_id&category=$category&subcat=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";}
    $string .= "</select>";
    return $string;    
	
}


sub getMotoSubCategory {
    $lang = $query->param("lang");    
    my $category = $query->param("category");
        my  ($c)= $db->sqlSelectMany("DISTINCT libelle.libelle","subcategorie_libelle_langue, libelle, langue","subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' AND subcategorie_libelle_langue.ref_categorie = 6");
    my $departement = $query->param("departement");
    my $selected = $query->param ("categegory");
    my $string = "<select name=\"subcategory\" onchange=\"go2();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    if ($selected) {$string  .= "<option selected value=\"$selected\">$selected</option>";}
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();    
    while(($OPTIONS{'category'})=$c->fetchrow()) {$string .= "<option VALUE=\"/cgi-bin/j.pl?lang=$lang&amp;page=moto&amp;session=$session_id&category=$category&subcat=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>" ;}
    $string .= "</select>";
    return $string;    
	
}

#loadCalendrier

sub getCalendrierCategory {
    my $category = $query->param("category");
    my  ($c)= sqlSelectMany("libelle.libelle","categorie_libelle_langue, libelle, langue","categorie_libelle_langue.ref_categorie = 57 or categorie_libelle_langue.ref_categorie = 79 AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my $selected = $query->param("category");
    my $string = "<select name=\"category\" onchange=\"go();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    if ($selected) {$string  .= "<option selected value=\"$selected\">$selected</option>";}
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();    
    while(($OPTIONS{'category'})=$c->fetchrow()) {$string .= "<option VALUE=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=calendrier&amp;session=$session_id&category=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>" ;}
    $string .= "</select>";
    return $string;    
	
}

sub getCalendrierSearchSubCategory {
    my $category = $query->param("category");
    my  ($c)= sqlSelectMany("libelle.libelle","subcategorie_libelle_langue, libelle, langue","categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' AND libelle = '$category'");
    my $selected = $query->param("category");
    my $string = "<select name=\"subcat\" onchange=\"go2();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    if ($selected) {$string  .= "<option selected value=\"$selected\">$selected</option>";}
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();    
    while(($OPTIONS{'category'})=$c->fetchrow()) {$string .= "<option VALUE=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=search_calendrier&amp;session=$session_id&subcat=$OPTIONS{'category'}&category=$category\">$OPTIONS{'category'}</option>" ;}
    $string .= "</select>";
    return $string;    
	
}

sub getCarCategory {
    $lang = $query->param("lang");
    loadLanguage();    
    my $category = $query->param("category");
    my  ($c)= $db->sqlSelectMany("libelle.libelle","subcategorie_libelle_langue, libelle, langue","subcategorie_libelle_langue.ref_categorie = 5 AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my $selected = $query->param("category");
    my $string = "<select name=\"category\" onchange=\"go();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    if ($selected) {$string  .= "<option selected value=\"$selected\">$selected</option>";}
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();    
    while(($OPTIONS{'category'})=$c->fetchrow()) {$string .= "<option VALUE=\"/cgi-bin/i.pl?lang=$lang&amp;page=auto&amp;session=$session_id&subcat=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>" ;}
    $string .= "</select>";
    return $string;    
	
}
sub loadCalendrierIndex {
    my  $cat = shift || '';
    my  $type = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $depot = $query->param("depot");$depot =~ s/\W//g;
    my $category = $query->param("category");
    my $subcat = $query->param("subcat");
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  $add = "";
    my $from; 
    if ($category) {$from .= " , categorie_libelle_langue, libelle, langue";
                    $add .= " AND libelle.libelle = '$category' AND article.ref_categorie = categorie_libelle_langue.ref_categorie AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'";
    }else {
	$add .= " AND article.ref_categorie = 57 OR 79 AND article.ref_categorie = categorie_libelle_langue.ref_categorie AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'";
	 }
    
    if ($subcat) {$from .= ", subcategorie_libelle_langue";
         $add .= " AND subcategorie_libelle_langue.id_subcategorie_libelle_langue = (SELECT libelle.libelle FROM subcategorie_libelle_langue, libelle, langue WHERE libelle.libelle = '$subcat' AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang') AND article.ref_subcategorie = subcategorie_libelle_langue.ref_subcategorie";
    }
    my $country_swiss = $query->param("country_swiss");my $country_france = $query->param("country_france");my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");my $with_lang_italian = $query->param("with_lang_italian");my $with_lang_english = $query->param("with_lang_english");
    my  ($c)= sqlSelect("count(id_article)","article,met_en_vente $from","ref_article = id_article AND ref_statut = '3' AND  enchere_date_fin > '$date% ' AND quantite > 0 $add  ");			
    my  $nb_page = arrondi ($c / 40, 1);my  $min_index = '0';my  $max_index = '40';    
    for (my  $i = '0'; $i < $nb_page;$i++) {my $j;if ($i <= 9) {$j = "0$i";}else {$j = $i;}
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=calendar&session=$session_id&amp;min_index=$min_index&amp;max_index=$max_index&country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=with_lang_french&with_lang_italian=$with_lang_italian&amp;with_lang_german=with_lang_german&with_lang_english=$with_lang_english\"  class=\"menulink2\" ><-$j-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }        
return $string;    
}

sub getBabyCategory {
    my $category = $query->param("category");
    $lang = $query->param("lang");
    loadLanguage();
    my  ($c)= $db->sqlSelectMany("libelle.libelle","categorie_libelle_langue, libelle, langue","categorie_libelle_langue.ref_categorie = 23 AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my $selected = $query->param("category");
    my $string = "<select name=\"category\" onchange=\"go();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    if ($selected) {$string  .= "<option selected value=\"$selected\">$selected</option>";}
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();    
    while(($OPTIONS{'category'})=$c->fetchrow()) {$string .= "<option VALUE=\"/cgi-bin/e.pl?lang=$lang&amp;page=baby&amp;session=$session_id&category=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>" ;}
    $string .= "</select>";
    return $string;    
	
}
sub getBabySubCategory {
    my $category = $query->param("category");
    $lang = $query->param("lang");
    loadLanguage();
    my  ($c)= $db->sqlSelectMany("DISTINCT libelle.libelle","subcategorie_libelle_langue, libelle, langue","subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' AND subcategorie_libelle_langue.ref_categorie = (SELECT categorie_libelle_langue.ref_categorie FROM categorie_libelle_langue, libelle, langue WHERE libelle.libelle ='$category' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang')");
    my $selected = $query->param("subcat");
    my $string = "<select name=\"subcat\" onchange=\"go2();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("departement");
    if ($selected) {$string  .= "<option selected value=\"$selected\">$selected</option>";}
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();    
    while(($OPTIONS{'category'})=$c->fetchrow()) {$string .= "<option VALUE=\"/cgi-bin/e.pl?lang=$lang&amp;page=baby&amp;session=$session_id&category=$category&subcat=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>" ;}
    $string .= "</select>";
    return $string;    
	
}




sub loadGamesMenu {
    $lang = $query->param("lang");
    loadLanguage();
    
    my  ($c)= $db->sqlSelectMany("libelle.libelle","categorie_libelle_langue, libelle, langue","(categorie_libelle_langue.ref_categorie = 11 or categorie_libelle_langue.ref_categorie = 95 )and categorie_libelle_langue.ref_libelle = libelle.id_libelle and categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'	");
    my $selected = $query->param("category");
    my $string = "<select name=\"category\" onchange=\"go();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("departement");
    if ($selected) {$string  .= "<option selected value=\"$selected\">$selected</option>";}
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();    
    while(($OPTIONS{'category'})=$c->fetchrow()) {$string .= "<option VALUE=\"/cgi-bin/r.pl?lang=$lang&amp;page=games&session=$session_id&category=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>" ;}
    $string .= "</select>";
    return $string;    
}

sub loadGamesSubMenu {
    $lang = $query->param("lang");
    loadLanguage();    
    my $category = $query->param("category");
    my @category_sub =$db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and categorie_libelle_langue.ref_libelle = libelle.id_libelle and categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
    my $cat_ref = $category_sub[0];
    my $selected = $query->param("subcat");
    my $string = "<select name=\"subcat\" onchange=\"go2();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("departement");
    if ($selected) {$string  .= "<option selected value=\"$selected\">$selected</option>";}
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    if ($cat_ref) {
      my  ($c)= $db->sqlSelectMany("DISTINCT libelle.libelle","subcategorie_libelle_langue,categorie_libelle_langue, libelle, langue","subcategorie_libelle_langue.ref_categorie = $cat_ref and subcategorie_libelle_langue.ref_libelle = libelle.id_libelle and subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
       while(($OPTIONS{'category'})=$c->fetchrow()) {$string .= "<option VALUE=\"/cgi-bin/r.pl?lang=$lang&amp;page=games&session=$session_id&category=$category&subcat=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>" ;}
   	#code
    }
    
    
    $string .= "</select>";
    return $string;    
	
}
sub loadGamesType {
    my $category = $query->param("category");
    my $subcat = $query->param("subcat");
    my  ($c)= sqlSelectMany("libelle.libelle","type_de_jeux_libelle_langue, libelle, langue","type_de_jeux.ref_libelle = libelle.id_libelle AND type_de_jeux.ref_langue = langue.id_langue AND langue.key = '$lang')");
    my $selected = $query->param("game_type");
    my $string = "<select name=\"game_type\" onchange=\"go3();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";    
    if ($selected) {$string  .= "<option selected value=\"$selected\">$selected</option>";}
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();    
    while(($OPTIONS{'category'})=$c->fetchrow()) {$string .= "<option VALUE=\"/cgi-bin/r.pl?lang=$lang&amp;page=games&session=$session_id&category=$category&subcat=$subcat&game_type=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>" ;}
    $string .= "</select>";

}


sub loadAstroCategory {
    my $category = $query->param("category");
    my $subcat = $query->param("subcat");
    my  ($c)= $db->sqlSelectMany("libelle.libelle","categorie_libelle_langue, libelle, langue","categorie_libelle_langue.ref_categorie = 32 AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my $string = "<select name=\"category\" onchange=\"go();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";    
    if ($category) {$string  .= "<option selected value=\"$category\">$category</option>";}
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();    
    while(($OPTIONS{'category'})=$c->fetchrow()) {	
	$string .= "<option VALUE=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=astro&session=$session_id&category=$OPTIONS{'category'}&subcat=$subcat\">$OPTIONS{'category'}</option>" ;}
	$string .= "</select>";
    return $string;    
	
}

sub loadAstroSubCategory {
    my $category = $query->param("category");
    my $subcat = $query->param("subcat");
    my  ($c)= $db->sqlSelectMany("libelle.libelle","subcategorie_libelle_langue, libelle, langue","subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' AND subcategorie_libelle_langue.ref_categorie = (SELECT categorie_libelle_langue.ref_categorie FROM categorie_libelle_langue, libelle, langue WHERE libelle.libelle ='$category' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang')");
    my $selected = $query->param("subcat");
    my $string = "<select name=\"subcat\" onchange=\"go2();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";    
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	$string .= "<option VALUE=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=astro&session=$session_id&category=$category&subcat=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";
    }
    $string .= "</select>";
    return $string;    
}


sub loadAstroIndex {
    my  $cat = shift || '';my  $type = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $depot = $query->param("depot");
    $depot =~ s/[^A-Za-z0-9 ]//;
    my $category = $query->param("category");
    my $subcat = $query->param("subcat");
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  $add;
    my $from;
    if ($category) {
	$from .= ",categorie_libelle_langue, libelle, langue";
	$add .= " AND articlce.ref_categorie = categorie_libelle_langue.ref_categorie AND libelle.libelle = '$category' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";}
    if ($subcat) {
	$from .= ",subcategorie_libelle_langue ";
	$add .= " AND article.ref_subcategorie = subcategorie_libelle_langue.ref_subcategorie AND libelle.libelle = '$subcat' AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'";}
    my $country_swiss = $query->param("country_swiss");my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");my $with_lang_english = $query->param("with_lang_english");
    my  ($c)= sqlSelect("count(id_article)","article,met_en_vente $from","ref_article = id_article AND ref_statut = '3' AND  enchere_date_fin > '$date% ' AND quantite > 0 $add AND (article.ref_categorie = 77)");	
    my  $nb_page = arrondi ($c / 40, 1);
    my  $min_index = '0'; my  $max_index = '40';    
    for (my  $i = '0'; $i < $nb_page;$i++) {	
	my $j;if ($i <= 9) {$j = "0$i";}else {$j = $i;}
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=games&session=$session_id&amp;min_index=$min_index&amp;max_index=$max_index&country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=with_lang_french&with_lang_italian=$with_lang_italian&amp;with_lang_german=with_lang_german&with_lang_english=$with_lang_english\"  class=\"menulink2\" ><-$j-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }
        
return $string;    
}




sub loadDvdCategories {
    $lang = $query->param("lang");	
    my  ($c)= $db->sqlSelectMany("libelle.libelle",
			   "subcategorie_libelle_langue, libelle, langue",
			   "subcategorie_libelle_langue.ref_categorie = 38 AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue");
    my $selected = $query->param("category");
    my $string = "<select name=\"subcategory\" onchange=\"go();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("departement");
    if ($selected) {
	
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option VALUE=\"/cgi-bin/t.pl?lang=$lang&amp;page=dvd&amp;session=$session_id&category=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select>";
    return $string;    
	
}

sub loadBookCategories {
	$lang = $query->param("lang");	
    loadLanguage();    
    my  ($c)= $db->sqlSelectMany("libelle.libelle",
			   "subcategorie_libelle_langue, langue, libelle",
			   "subcategorie_libelle_langue.ref_categorie = 9 AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my $selected = $query->param("subcategory");
    my $string = "<select name=\"subcategory\" onchange=\"go();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("departement");
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option VALUE=\"/cgi-bin/s.pl?lang=$lang&amp;page=book&amp;session=$session_id&subcategory=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select>";
    return $string;    
	
}

sub loadBookIndex {
    my  $cat = shift || '';
    my  $type = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $depot = $query->param("depot");
    $depot =~ s/[^A-Za-z0-9 ]//;
    my $category = $query->param("category");
    my $subcat = $query->param("subcat");
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  $add;
    my $from;
   if ($category) {$from .= ", categorie_libelle_langue, libelle, langue";
                    $add .= " AND libelle.libelle = '$category' AND article.ref_categorie = categorie_libelle_langue.ref_categorie AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'";}
    if ($subcat) {$from .= ", subcategorie_libelle_langue";
                    $add .= " AND subcategorie_libelle_langue.ref_subcategorie_libelle_langue = (SELECT subcategorie_libelle_langue.ref_subcategorie FROM subcategorie_libelle_langue, libelle, langue WHERE libelle.libelle = '$subcat' AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang') AND article.ref_subcategorie = subcategorie_libelle_langue.ref_subcategorie";
                    }
    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");

    my  ($c)= sqlSelect("count(id_article)",
			   "article,met_en_vente $from",
			   "ref_article = id_article AND ref_statut = '3' AND  enchere_date_fin > '$date% ' AND quantite > 0 $add AND article.ref_categorie = 27");	
	

    my  $nb_page = arrondi ($c / 40, 1);
    my  $min_index = '0';
    my  $max_index = '40';
    
    #print "Content-Type: text/html\n\n";
    for (my  $i = '0'; $i < $nb_page;$i++) {	
	#my $x =
	my $j;
	#print "valeur de i $i <br />";
	if ($i <= 9) {
		$j = "0$i";
	}else {
		$j = $i;
	}
	$string .= "<a href=\"/cgi-bin/main.pl?lang=$lang&amp;page=book&amp;session=$session_id&amp;min_index=$min_index&amp;max_index=$max_index&country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=with_lang_french&with_lang_italian=$with_lang_italian&amp;with_lang_german=with_lang_german&with_lang_english=$with_lang_english\"  class=\"menulink2\" ><-$j-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }
        
return $string;    
}

sub loadBookByIndex {
    my  $cat = shift || '';
    my  $type = shift  || '';
    my  $depot = $query->param("depot") ;
    $depot=~ s/[^A-Za-z0-9 ]//;
    my  $index_start = $query->param ("min_index");
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index");
    $index_end =~ s/[^A-Za-z0-9 ]//;
    my $category = $query->param("category");
    my $subcat = $query->param("subcat");
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    $date = trimwhitespace($date);
    my  $string = "";
    my  $add;
    my $from;
    if ($category) {$from .= ", categorie_libelle_langue, libelle, langue";
                    $add .= " AND libelle.libelle = '$category' AND article.ref_categorie = categorie_libelle_langue.ref_categorie AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'";}
    if ($subcat) {$from .= ", subcategorie_libelle_langue";
                    $add .= " AND subcategorie_libelle_langue.ref_subcategorie_libelle_langue = (SELECT ref_subcategorie FROM subcategorie_libelle_langue, libelle, langue WHERE libelle.libelle = '$subcat' AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang') AND article.ref_subcategorie = subcategorie_libelle_langue.ref_subcategorie";
                    }
     
    if (!$index_start ) {
	$index_start = 0;
    }
    if (!$index_end ) {
	$index_end = 40;
    }

   $add .= getAdd();    

    my  ($c)= sqlSelectMany("DISTINCT article.nom,marque,prix, pochette,id_article,date_stock,article.ref_categorie,article.lieu,quantite",
		       "article,met_en_vente $from",
		       "ref_article = id_article  AND ref_statut = '3' and quantite > 0 AND  enchere_date_fin > "." '$date%' AND article.ref_categorie = 27 $add ORDER BY  date_stock DESC LIMIT $index_start, $index_end  ");	
    
#	$string .= "<br />";
#	$string .= "<table width=\"500\" border=\"0\">";
#	$string .= "<tr>";
#	$string .= "<td align=\"left\">&nbsp;</td>";
#	$string .=  "<td align=\"left\">&nbsp;</td>";
#	$string .=  "<td align=\"leftf\">&xcvxcv;xcvxc</td>";
#	$string .=  "</tr>";

    my $i = 0;
    
    my $j = 0;
    #$string .= "<hr>";
    $string .= "<table style=\"border-top-width:medium;border-top-color:#94CEFA\"><tr>";
    
    while( ($ARTICLE{'name'},$ARTICLE{'author'},$ARTICLE{'price'},$ARTICLE{'pochette'},$ARTICLE{'id_article'},$ARTICLE{'date'},$ARTICLE{'ref_categorie'},$ARTICLE{'article_lieu'},$ARTICLE{'quantity'})=$c->fetchrow()) {
	#$string .= " <label>&nbsp;&nbsp;$ARTICLE{'genre'}</label>";
	my $img;
	if ($ARTICLE{'pochette'} eq '') {
		$ARTICLE{'pochette'} = "../images/no.gif";
	}
	
	if ($ARTICLE{'date'} eq $date) {
		$img = "../images/new_article.gif"
	}else {
		##$img = "../images/blank.gif"
	}
	my $add3;
	if ($ARTICLE{'ref_categorie'} eq '11') {
		$add3 = $ARTICLE{'article_lieu'};
	}
	#$ARTICLE{'label'}
	#$ARTICLE{'label'} .= "...";

	$string .= "<td align=\"left\" width=\"253px\" height=\"100px\" style=\"background-image:url(../images/table_article_decoration.jpg);background-position:right bottom;background-repeat: no-repeat;\">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&amp;action=detailother&amp;article=$ARTICLE{'id_article'}\" class=\"menulink3\" >$ARTICLE{'name'} $add3</a><br/>&nbsp;&nbsp;&nbsp;&nbsp;<img alt=\"\" src=\"$ARTICLE{'pochette'}\" /> <img alt=\"\" src=\"$img\" /><br/>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$ARTICLE{'price'} <br/><br/></td>";
	$i += 1;
	$j += 1;

	if ($i eq 1) {
		#$string .= "<hr>";
		$string .= "<td align=\"left\" width=\"10px\"></td>";		
		$i = 0;
	}
	
	if ($j eq 2) {
		
		$string .= "</tr>";
		$string .= "<tr>";
		$string .= "</tr>";
		$string .= "<tr>";
		$string .= "</tr>";
		$string .= "<tr>";		
		$j = 0;
	}
    }    
    $string .= "</table>";
    return $string;
    
}




sub loadSearchWatchFabricant {
    my $category = $query->param("category");
    my $subcategory = $query->param("subcategory");
    my $fabricant = $query->param("fabricant");
    my $type = $query->param("type");
    loadLanguage();
    my $string .= "<td align=\"left\">$SERVER{'fabricant'}</td>";
    $string .= "<td align=\"left\"><select name=\"fabricant\"  onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
   
    if ($category && $subcategory) {
    
    my  ($categoryID)=$db->sqlSelect("ref_categorie", "categorie_libelle_langue,langue, libelle", "libelle.libelle = '$category' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my  ($subcategoryID)=$db->sqlSelect("ref_subcategorie", "subcategorie_libelle_langue,langue, libelle", "libelle.libelle = '$subcategory' AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my  ($c)= $db->sqlSelectMany("DISTINCT marque",
			   "article",
			   "article.ref_subcategorie = $subcategoryID and article.ref_categorie = $categoryID");
    
    
    
    my  %OPTIONS = ();

    
    if ($fabricant) {
	$string  .= "<option selected value=\"$fabricant\" onblur=\"skipcycle=false\">$fabricant</option>";
    }
    $string  .= "<option value=\"\" onblur=\"skipcycle=false\">--------</option>";
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {	
         $string .= "<option onblur=\"skipcycle=false\" VALUE=\"$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";
	}
    }
    $string .= "</select>";
    $string .= "</td>";
    return $string;    
	
}

sub loadSearchJardinFabricant {
    my $category = $query->param("category");
    my $subcategory = $query->param("subcategory");
    my $fabricant = $query->param("fabricant");
    my $type = $query->param("type");
    my $string .= "<td align=\"left\">$SERVER{'fabricant'}</td>";
    $string .= "<td align=\"left\"><select name=\"fabricant\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
   
    if ($category && $subcategory) {
    
    my  ($categoryID)=$db->sqlSelect("ref_categorie", "categorie_libelle_langue,langue, libelle", "libelle.libelle = '$category' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my  ($subcategoryID)=$db->sqlSelect("ref_subcategorie", "subcategorie_libelle_langue,langue, libelle", "libelle.libelle = '$subcategory' AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my  ($c)= $db->sqlSelectMany("DISTINCT marque",
			   "article",
			   "article.ref_subcategorie = $subcategoryID and article.ref_categorie = $categoryID");
    
    
    
    my  %OPTIONS = ();

    
    if ($fabricant) {
	$string  .= "<option selected value=\"$fabricant\" onblur=\"skipcycle=false\">$fabricant</option>";
    }
    $string  .= "<option value=\"\" onblur=\"skipcycle=false\">--------</option>";
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {	
                  $string .= "<option onblur=\"skipcycle=false\" VALUE=\"$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";
	}
    }
    $string .= "</select>";
    $string .= "</td>";
    return $string;    
	
}

sub loadSearchUsed {
	my $string .= "<tr><td>$SERVER{'used'}</td><td>";
	my  ($c)= sqlSelectMany("libelle.libelle",
			   "etat_libelle_langue,libelle, langue",
			   "etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
	$string .= "<select name=\"used\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\" >";
	my  %OPTIONS = ();
	while(($OPTIONS{'category'})=$c->fetchrow()) {	
		$string .= "<option value=\"$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";
	}
	$string .= "</select></td></tr>";
	return $string;
}

sub loadSearchMuzikCategories {
    my $category = $query->param("category");
    $lang = $query->param("lang");
    my  ($c)= $db->sqlSelectMany("libelle.libelle",
			   "categorie_libelle_langue, libelle,langue",
			   "categorie_libelle_langue.ref_categorie BETWEEN 39 AND 41 AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my $string = "<select name=\"category\" onchange=\"go3();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    $string  .= "<option value=\"\">-----------</option>";
    if ($category) {
	$string  .= "<option selected value=\"$category\">$category</option>";
    }

    #$string  .= "<option selected value=\"$selected\">$selected</option>";
    my  %OPTIONS = ();
    while(($OPTIONS{'category'},$OPTIONS{'code'})=$c->fetchrow()) {
         $string .= "<option VALUE=\"/cgi-bin/l.pl?lang=$lang&amp;page=cd_vinyl_mixtap&show_popup=true&session=$session_id&category=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select>";
    return $string;    

}
sub loadSearchImmoDepartement {
    my $departement = $query->param("departement");
    my $canton = $query->param("canton");
    my $country = $query->param("country");    
    my $immo_type = $query->param("immo_type");
    my $location_type = $query->param("location_type");

    my  ($c)= $db->sqlSelectMany("nom,code",
			   "departement",
			   "id_departement = id_departement");    
    my $string = "<select name=\"departement\" onchange=\"go5();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    if ($departement) {
	$string  .= "<option selected value=\"$departement\">$departement</option>";
    }

    #$string  .= "<option selected value=\"$selected\">$selected</option>";
    my  %OPTIONS = ();
    while(($OPTIONS{'category'},$OPTIONS{'code'})=$c->fetchrow()) {
	
         $string .= "<option VALUE=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=search_immo&session=$session_id&category=$OPTIONS{'category'}&country=$country&departement=$OPTIONS{'category'}&canton=$canton&immo_type=$immo_type&location_type=$location_type\">$OPTIONS{'category'}($OPTIONS{'code'})</option>" ;
	}
    $string .= "</select>";
    return $string;    
	
}

sub loadSearchImmoMode {
    my $location_type = $query->param("location_type");
    my $country = $query->param("country");
    my $canton = $query->param("canton");
    my $departement = $query->param("departement");
    my $immo_type = $query->param("immo_type");
    my  ($c)= $db->sqlSelectMany("libelle.libelle",
			   "location_ou_achat_libelle_langue, libelle, langue",
			   "location_ou_achat_libelle_langue.ref_libelle = libelle.id_libelle AND location_ou_achat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    
    my $string = "<select name=\"mode\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    
    my  %OPTIONS = ();

    if ($location_type) {
	$string  .= "<option selected value=\"$location_type\">$location_type</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option VALUE=\"$OPTIONS{'category'}\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select>";
    return $string;    
	
}

sub loadImmobilierLocationOuAchat {
    my $u = $query->param("u");
    my $location_type = $query->param("location_type");
    my $country = $query->param("country_name");
    my $canton = $query->param("canton");
    my $departement = $query->param("departement");
    my $location_ou_achat = $query->param("location_ou_achat");    
    my $subcategory = $query->param("subcategory");    
    my  ($c)= $db->sqlSelectMany("libelle.libelle",
			   "location_ou_achat_libelle_langue, libelle, langue",
			   "location_ou_achat_libelle_langue.ref_libelle = libelle.id_libelle AND location_ou_achat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    
    my $string = "<select name=\"location_ou_achat\" onchange=\"go4();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    
    my  %OPTIONS = ();

    if ($location_ou_achat) {
	$string  .= "<option selected value=\"$location_ou_achat\">$location_ou_achat</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option VALUE=\"/cgi-bin/immo.pl?lang=$lang&amp;page=immo&departement=$departement&subcategory=$subcategory&country_name=$country&session=$session_id&location_type=$location_type&location_ou_achat=$OPTIONS{'category'}&u=$u&country_name=$country&canton=$canton&departement=$departement\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select>";
    return $string;    
	
}


sub loadLoyer {
	my $string;
	$string .= "";
	$string .= "<td align=\"left\">Location prix min </td><td align=\"left\"><input type=\"text\" name=\"buy_price_min\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\" value=\"\"></td><td align=\"left\">Location prix max</td><td align=\"left\"><input type=\"text\" name=\"buy_price_max\" value=\"\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
	$string .= "</td></tr>";
	$string .= "<tr>";
	$string .= "<td align=\"left\">Nombre de pi�ces :</td><td align=\"left\"><input type=\"text\" name=\"nbr_piece\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\" value=\"\"></td>";
	$string .= "</tr>";
	$string .= "<tr>";
	$string .= "<td align=\"left\">Meubl�</td><td align=\"left\"><input type=\"checkbox\" name=\"is_meubled_yes\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td>";
	$string .= "</tr>";
	$string .= "<tr>";
	$string .= "<td align=\"left\">Surface habitable</td><td align=\"left\"><input type=\"text\" name=\"habitable_surface\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\" value=\"\"></td>";
	$string .= "</tr>";

	return $string;	
}

sub loadAppartBuy {
	my $string;
	$string .= "";
	$string .= "<td align=\"left\">CHF d'achat min </td><td align=\"left\"><input type=\"text\" name=\"buy_price_min\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\" value=\"\"></td><td align=\"left\">CHF d'achat max</td><td align=\"left\"><input type=\"text\" name=\"buy_price_max\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\" value=\"\">";
	$string .= "</td></tr>";
	$string .= "<tr>";
	$string .= "<td align=\"left\">Nombre de pi�ces :</td><td align=\"left\"><input type=\"text\" name=\"nbr_piece\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\" value=\"\"></td>";
	$string .= "</tr>";
	$string .= "<tr>";
	$string .= "<td align=\"left\">Meubl�</td><td align=\"left\"><input type=\"checkbox\" name=\"is_meubled_yes\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td>";
	$string .= "</tr>";
	$string .= "<tr>";
	$string .= "<td align=\"left\">Surface habitable</td><td align=\"left\"><input type=\"text\" name=\"habitable_surface\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\" value=\"\"></td>";
	$string .= "</tr>";

	return $string;
	
}
sub loadInfoFabricant {
    my $category = $query->param("category");
    my $fabricant = $query->param("fabricant");
    my $type = $query->param("type");
    
    my  ($c)= sqlSelectMany("DISTINCT marque",
			   "article,subcategorie_libelle_langue, libelle, langue",
			   "ref_subcategorie = (select id_subcategorie from subcategorie_libelle_langue, libelle, langue where libelle.libelle = '$category' AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'" );
    
    my $string .= "<td align=\"left\">$SERVER{'fabricant'}</td>";
    $string .= "<td align=\"left\"><select name=\"fabricant\" onchange=\"go3();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    
    my  %OPTIONS = ();

    
    if ($fabricant) {
	$string  .= "<option selected value=\"$fabricant\" onblur=\"skipcycle=false\">$fabricant</option>";
    }
    $string  .= "<option value=\"\" onblur=\"skipcycle=false\">--------</option>";
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option onblur=\"skipcycle=false\" VALUE=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=search_info&session=$session_id&fabricant=$OPTIONS{'category'}&type=$type&category=$category\">$OPTIONS{'category'}</option>";
	}
    $string .= "</select>";
    $string .= "</td>";
    return $string;    	
}

sub loadInfoCategory {
    my $category = $query->param("category");
    my $type = $query->param("type");
    
    my  ($c)= sqlSelectMany("libelle.libelle",
			   "subcategorie__libelle_langue, langue, libelle",
			   "subcategorie__libelle_langue.ref_categorie = 10 AND subcategorie__libelle_langue.ref_libelle = libelle.libelle AND subcategorie__libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    
    my $string .= "<td align=\"left\">$SERVER{'category'}</td>";
    $string .= "<td align=\"left\"><select name=\"category\" onchange=\"go();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    
    my  %OPTIONS = ();
    
    if ($category) {
	$string  .= "<option selected value=\"$category\" onblur=\"skipcycle=false\">$category</option>";
    }
    $string  .= "<option value=\"\" onblur=\"skipcycle=false\">--------</option>";
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option onblur=\"skipcycle=false\" VALUE=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=search_info&session=$session_id&category=$OPTIONS{'category'}&type=$type\">$OPTIONS{'category'}</option>";
	}
    $string .= "</select>";
    $string .= "</td>";
    return $string;    
	
}

sub loadSearchInfoEcranDimension {
	my $string;
	$string .= "<tr>";
	$string .= "<td align=\"left\">$SERVER{'dimension_min'}</td><td align=\"left\"><input type=\"text\" name=\"ecran_dimension_min\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td><td align=\"left\">$SERVER{'dimension_max'}</td><td align=\"left\"><input type=\"text\" name=\"ecran_dimension_max\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td>";
	$string .= "</tr>";

	$string .= "<tr>";
	$string .= "<td align=\"left\">$SERVER{'price_min'}</td><td align=\"left\"><input type=\"text\" name=\"price_min\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td><td align=\"left\">$SERVER{'price_max'}</td><td align=\"left\"><input type=\"text\" name=\"price_max\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td>";
	$string .= "</tr>";
	$string .= "<tr><td>$SERVER{'used'}</td><td>";
	my  ($c)= sqlSelectMany("libelle.libelle",
			   "etat_libelle_langue, langue, libelle",
			   "etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
	$string .= "<select name=\"used\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\" >";
	my  %OPTIONS = ();
	while(($OPTIONS{'category'})=$c->fetchrow()) {	
		$string .= "<option value=\"$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";
	}
	$string .= "</select></td></tr>";

	return $string;
}
sub loadSearchInfoPcProperties {
	my $string;
	$string .= "<tr>";
	$string .= "<td align=\"left\">$SERVER{'processor_min'}</td><td align=\"left\"><input type=\"text\" name=\"processor_min\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td><td align=\"left\">$SERVER{'processor_max'}</td><td align=\"left\"><input type=\"text\" name=\"processor_max\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td>";
	$string .= "</tr>";

	$string .= "<tr>";
	$string .= "<td align=\"left\">$SERVER{'ram_min'}</td><td align=\"left\"><input type=\"text\" name=\"ram_min\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td><td align=\"left\">$SERVER{'ram_max'}</td><td align=\"left\"><input type=\"text\" name=\"ram_max\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td>";
	$string .= "</tr>";

	$string .= "<tr>";
	$string .= "<td align=\"left\">$SERVER{'hard_drive_min'}</td><td align=\"left\"><input type=\"text\" name=\"hard_drive_min\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td><td align=\"left\">$SERVER{'hard_drive_max'}</td><td align=\"left\"><input type=\"text\" name=\"hard_drive_max\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td>";
	$string .= "</tr>";

	$string .= "<tr>";
	$string .= "<td align=\"left\">$SERVER{'price_min'}</td><td align=\"left\"><input type=\"text\" name=\"price_min\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td><td align=\"left\">$SERVER{'price_max'}</td><td align=\"left\"><input type=\"text\" name=\"price_max\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td>";
	$string .= "</tr>";

	$string .= "<tr><td>$SERVER{'used'}</td><td>";
	my  ($c)= sqlSelectMany("libelle.libelle",
			   "etat_libelle_langue,libelle, langue",
			   "etat_libelle_langue_ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
	$string .= "<select name=\"used\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\" >";
	my  %OPTIONS = ();
	while(($OPTIONS{'category'})=$c->fetchrow()) {	
		$string .= "<option value=\"$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";
	}
	$string .= "</select></td></tr>";

	return $string;
	
}

sub getSearchWearSex {
    my $genre = $query->param("genre");
          
    my  $string .= "<select name=\"genre\" onchange=\"go();\" onfocus=\"skipcycle=true;\" onblur=\"skipcycle=false\">";
    my  ($c)= sqlSelectMany("libelle.libelle","categorie_libelle_langue, libelle, langue","categorie_libelle_langue.ref_categorie BETWEEN 6 AND 7 AND categorie_libelle_langue.ref_libelle = libelle.libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    $string .= "<option>------</option>";    
    if ($genre) {
	$string .= "<option selected value=\"$genre\">$genre</option>";
    }

    while( ($ARTICLE{'genre'})=$c->fetchrow()) {
	$string .= "<option value=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=search_wear&session=$session_id&genre=$ARTICLE{'genre'}\">$ARTICLE{'genre'}</option>";
    }
    $string .= "</select>";
    return $string;
}	

sub getSearchWearType {
    my $genre = $query->param("genre");
    my $subcat = $query->param("subcat");
          
    my  $string .= "<select name=\"category\" onchange=\"go2();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my  ($c)= $db->sqlSelectMany("libelle.libelle","subcategorie_libelle_langue, libelle, langue","subcategorie_libelle_langue.ref_categorie = (SELECT ref_categorie FROM categorie_libelle_langue, libelle, langue WHERE libelle.libelle = '$genre' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue)'");
    if ($subcat) {
	$string .= "<option selected value=\"$subcat\">$subcat</option>";
    }

    $string .= "<option>------</option>"; 
    while( ($ARTICLE{'genre'})=$c->fetchrow()) {
	$string .= "<option value=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=search_wear&amp;type=6&session=$session_id&genre=$genre&subcat=$ARTICLE{'genre'}\">$ARTICLE{'genre'}</option>";
    }
    $string .= "</select>";
    return $string;
}	

sub loadWearFabricant {
    my $genre = $query->param("genre");	
    my $subcat = $query->param("subcat");
    my $fabricant = $query->param("fabricant");
    
    my  ($sexID)=sqlSelect("ref_categorie", "categorie_libelle_langue, libelle, langue", "libelle.libelle = '$genre' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND  categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    
    my  ($c)= sqlSelectMany("DISTINCT marque",
			   "article,subcategorie_libelle_langue ,categorie_libelle_langue",
			   "AND article.ref_categorie = $sexID AND subcategorie_libelle_langue.ref_subcategorie = (select subcategorie_libelle_langue.ref_subcategorie from subcategorie_libelle_langue where libelle.libelle = '$subcat' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')");
    
    my $string .= "<td align=\"left\">$SERVER{'fabricant'}</td>";
    $string .= "<td align=\"left\"><select name=\"fabricant\" onchange=\"go3();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    
    my  %OPTIONS = ();

    
    if ($fabricant) {
	$string  .= "<option selected value=\"$fabricant\" onblur=\"skipcycle=false\">$fabricant</option>";
    }
    $string  .= "<option value=\"\" onblur=\"skipcycle=false\">--------</option>";
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option onblur=\"skipcycle=false\" VALUE=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=search_wear&session=$session_id&fabricant=$OPTIONS{'category'}&genre=$genre&subcat=$subcat\">$OPTIONS{'category'}</option>";
	}
    $string .= "</select>";
    $string .= "</td>";
    return $string;    
	
}

sub loadSearchWearProperties {
	my $string;
    $lang = $query->param("lang");
    loadLanguage();
	$string .= "<tr>";
	$string .= "<td align=\"left\">$SERVER{'size'}</td><td align=\"left\"><input type=\"text\" name=\"taille\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td>";
	$string .= "</tr>";
	$string .= "<tr>";
	$string .= "<td align=\"left\">CHF min.</td><td align=\"left\"><input type=\"number\" step=\"1\" name=\"price_min\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td>";
	$string .= "<td align=\"left\">CHF max.</td><td align=\"left\"><input type=\"number\" step=\"1\" name=\"price_max\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td>";
	$string .= "</tr>";
	return $string;
}

sub loadCdVinylMixTapeCategories {
    my $string;
    $lang = $query->param("lang");
    loadLanguage();
    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");
	
	my $category = $query->param("category");
	my  ($c)= $db->sqlSelectMany("libelle.libelle",
			   "categorie_libelle_langue, libelle,langue",
			   "categorie_libelle_langue.ref_categorie BETWEEN 39 AND 41 AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
	$string = "<select name=\"category\" onchange=\"go();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
        if ($category) {
		$string  .= "<option selected value=\"$category\" onblur=\"skipcycle=false\">$category</option>";
	}

	my  %OPTIONS = ();
        $string  .= "<option value=\"\" onblur=\"skipcycle=false\">--------</option>";
     
       while(($OPTIONS{'category'})=$c->fetchrow()) {
 	
         $string .= "<option onblur=\"skipcycle=false\" VALUE=\"/cgi-bin/l.pl?lang=$lang&amp;page=cd_vinyl_mixtap&session=$session_id&category=$OPTIONS{'category'}&country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=with_lang_french&with_lang_italian=$with_lang_italian&amp;with_lang_german=with_lang_german&with_lang_english=$with_lang_english\">$OPTIONS{'category'}</option>";
	}
      $string .= "</select>";
      return $string;       	
}


sub loadSearchWearCategories {
    my $string;
    $lang = $query->param("lang");
    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");	
    my $category = $query->param("category");
    my $subcategory = $query->param("subcategory");
    my $fabricant = $query->param("fabricant");
    my  ($c)= $db->sqlSelectMany("libelle.libelle",
			   "categorie_libelle_langue, libelle,langue",
			   "categorie_libelle_langue.ref_categorie BETWEEN 1 AND 2 AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
     $string = "<select name=\"category\" onchange=\"go();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    if ($category) {
	    $string  .= "<option selected value=\"$category\" onblur=\"skipcycle=false\">$category</option>";
    }

    my  %OPTIONS = ();
    $string  .= "<option value=\"\" onblur=\"skipcycle=false\">--------</option>";
 
   while(($OPTIONS{'category'})=$c->fetchrow()) {
     $string .= "<option onblur=\"skipcycle=false\" VALUE=\"/cgi-bin/c.pl?lang=$lang&page=wear_news&show_popup=true&session=$session_id&category=$OPTIONS{'category'}&country_swiss=$country_swiss&country_france=$country_france&with_lang_french=$with_lang_french&with_lang_italian=$with_lang_italian&with_lang_german=$with_lang_german&with_lang_english=$with_lang_english&subcategory=$subcategory&fabricant=$fabricant\">$OPTIONS{'category'}</option>";
    }
  $string .= "</select>";
  return $string;       	
}

sub loadSearchWearSubCategories {
    my $string;
    $lang = $query->param("lang");
    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");	
    my $category = $query->param("category");
    my $subcategory = $query->param("subcategory");
    my $fabricant = $query->param("fabricant");
    $string = "<select name=\"subcategory\" onchange=\"go2();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    if ($category) {
	my  ($c)= $db->sqlSelectMany("libelle.libelle",
			       "subcategorie_libelle_langue, libelle,langue",
			       "subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' AND subcategorie_libelle_langue.ref_categorie = (SELECT ref_categorie FROM categorie_libelle_langue, libelle, langue WHERE libelle.libelle = '$category' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')");
	 
	if ($subcategory) {
		$string  .= "<option selected value=\"$subcategory\" onblur=\"skipcycle=false\">$subcategory</option>";
	}
    
	my  %OPTIONS = ();
	$string  .= "<option value=\"\" onblur=\"skipcycle=false\">--------</option>";
     
       while(($OPTIONS{'category'})=$c->fetchrow()) {
     $string .= "<option onblur=\"skipcycle=false\" VALUE=\"/cgi-bin/c.pl?lang=$lang&page=wear_news&show_popup=true&session=$session_id&category=$category&amp;subcategory=$OPTIONS{'category'}&country_swiss=$country_swiss&country_france=$country_france&with_lang_french=$with_lang_french&with_lang_italian=$with_lang_italian&with_lang_german=$with_lang_german&with_lang_english=$with_lang_english&subcategory=$subcategory&fabricant=$fabricant\">$OPTIONS{'category'}</option>";	
	 
	}
    }
  $string .= "</select>";
  return $string;       	
}

sub loadSearchWearFabricants {
    my $string;
    $lang = $query->param("lang");
    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");	
    my $category = $query->param("category");
    my $subcategory = $query->param("subcategory");
    my $fabricant = $query->param("fabricant");
    $string = "<select name=\"fabricant\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    if ($fabricant) {
	    $string  .= "<option selected value=\"$fabricant\" onblur=\"skipcycle=false\">$fabricant</option>";
    }

    my  %OPTIONS = ();
    $string  .= "<option value=\"\" onblur=\"skipcycle=false\">--------</option>";
    my $ref_cat;
    my $ref_subcat;
    my $add;
    my $add2;
    
    if ($category) {
	    my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $add .= " AND article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";

    }
    if ($subcategory) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcategory' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $add .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
    }
    if ($category && $subcategory) {
    my  ($c)= $db->sqlSelectMany1("DISTINCT article.marque",
			       "subcategorie_libelle_langue, article, categorie_libelle_langue, libelle, langue",
			       "article.ref_subcategorie = subcategorie_libelle_langue.ref_subcategorie AND article.ref_categorie = categorie_libelle_langue.ref_categorie $add");
	 
     
       while(($OPTIONS{'category'})=$c->fetchrow()) {
	
	 $string .= "<option onblur=\"skipcycle=false\" VALUE=\"$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";
    }
       }
  $string .= "</select>";
  return $string;       	
}


sub loadSearchAnimalFabricants {
    my $string;
    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");	
    my $category = $query->param("category");
    my $subcategory = $query->param("subcat");
    my $fabricant = $query->param("fabricant");
    $string = "<tr><td>$SERVER{'fabricant'}</td><td><select name=\"fabricant\" onchange=\"go3();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    if ($fabricant) {
	    $string  .= "<option selected value=\"$fabricant\" onblur=\"skipcycle=false\">$fabricant</option>";
    }

    my  %OPTIONS = ();
    $string  .= "<option value=\"\" onblur=\"skipcycle=false\">--------</option>";
    my $ref_cat;
    my $ref_subcat;
    my $add;
    my $add2;
    
    if ($category) {
	    my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $add .= " AND article.ref_categorie = 33 AND categorie_libelle_langue.ref_categorie = 33 and  article.ref_categorie = 33";

    }
    if ($subcategory) {
        my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcategory' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	   $add .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
    }
    
    my  ($c)= $db->sqlSelectMany("DISTINCT article.marque",
			       "subcategorie_libelle_langue, article, categorie_libelle_langue, libelle, langue",
			       "article.ref_subcategorie = subcategorie_libelle_langue.ref_subcategorie AND article.ref_categorie = categorie_libelle_langue.ref_categorie $add");
	 
     
      while(($OPTIONS{'category'})=$c->fetchrow()) {
	
	 $string .= "<option onblur=\"skipcycle=false\" VALUE=\"$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";
    }
       
  $string .= "</select></td><tr>";
  return $string;       	
}



sub loadCdVinylMixTapeSubCategories {
	my $category = $query->param("category");
    $lang = $query->param("lang");
    loadLanguage();
	my $subcat = $query->param("subcategory");
	my $string;
	my  ($c)= $db->sqlSelectMany("libelle.libelle","subcategorie_libelle_langue,libelle, langue",
			   "subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' AND subcategorie_libelle_langue.ref_categorie = (SELECT ref_categorie FROM categorie_libelle_langue, libelle, langue WHERE libelle.libelle = '$category' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')");
	$string = "$SERVER{'subcategory'} <select name=\"subcategory\" onchange=\"go2();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    
	my  %OPTIONS = ();
        $string  .= "<option value=\"\" onblur=\"skipcycle=false\">--------</option>";
        if ($subcat) {
		$string  .= "<option selected value=\"$subcat\" onblur=\"skipcycle=false\">$subcat</option>";
	}
       while(($OPTIONS{'category'})=$c->fetchrow()) {
 	
         $string .= "<option onblur=\"skipcycle=false\" VALUE=\"/cgi-bin/l.pl?lang=$lang&amp;page=cd_vinyl_mixtap&session=$session_id&subcat=$OPTIONS{'category'}&category=$category\">$OPTIONS{'category'}</option>";
	}
      $string .= "</select>";
      return $string;       	
}

sub loadSearchCdVinylMixTapeCategories {
	my $string;
	my $category = $query->param("category");
	my $production_house = $query->param("production_house");
	my  ($c)= $db->sqlSelectMany("libelle.libelle",
			   "categorie_libelle_langue, libelle, langue",
			   "id_categorie BETWEEN 13 AND  15 and categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
	$string = "<select name=\"category\" onchange=\"go();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
        if ($category) {
		$string  .= "<option selected value=\"$category\" onblur=\"skipcycle=false\">$category</option>";
	}

	my  %OPTIONS = ();
        $string  .= "<option value=\"\" onblur=\"skipcycle=false\">--------</option>";
     
       while(($OPTIONS{'category'})=$c->fetchrow()) {
 	
         $string .= "<option onblur=\"skipcycle=false\" VALUE=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=search_cd&session=$session_id&category=$OPTIONS{'category'}&production_house=$production_house\">$OPTIONS{'category'}</option>";
	}
      $string .= "</select>";
      return $string;       	
}

sub loadSearchCdVinylMixTapeSubCategories {
    $lang = $query->param("lang");
	my $category = $query->param("category");
	my $subcat = $query->param("subcategory");
	my $production_house = $query->param("production_house");	
	my $string;
	$string .= "<td align=\"left\">$SERVER{'subcategory'}</td>";
	
	my  ($c)= $db->sqlSelectMany("libelle.libelle","subcategorie_libelle_langue,libelle, langue",
			   "subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' AND subcategorie_libelle_langue.ref_categorie = (SELECT ref_categorie FROM categorie_libelle_langue, libelle, langue WHERE libelle.libelle = '$category' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')");
	$string .= "<td><select name=\"subcategory\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    
	my  %OPTIONS = ();
        $string  .= "<option value=\"\" onblur=\"skipcycle=false\">--------</option>";
        if ($subcat) {
		$string  .= "<option selected value=\"$subcat\" onblur=\"skipcycle=false\">$subcat</option>";
	}
       while(($OPTIONS{'category'})=$c->fetchrow()) {
 	
         $string .= "<option onblur=\"skipcycle=false\" VALUE=\"$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";
	}
      $string .= "</select></td>";
      return $string;       	
}

sub loadSearchCdProperties {
	my $category = $query->param("category");
	my $subcat = $query->param("subcategory");
	my $production_house = $query->param("production_house");
	my $string;
	$string .= "<tr>";
	$string .= "<td align=\"left\">Titre</td><td align=\"left\"><input type=\"text\" name=\"cd_title\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td>";
	$string .= "</tr>";

	$string .= "<tr>";
	$string .= "<td align=\"left\">Auteur/td><td align=\"left\"><input type=\"text\" name=\"cd_artist\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td>";
	$string .= "</tr>";

	$string .= "<tr>";
	$string .= "<td align=\"left\">Label</td>";
	
	my  ($c)= $db->sqlSelectMany("DISTINCT marque",
			   "article,categorie_libelle_langue,libelle, langue",
			   "article.ref_categorie = categorie_libelle_langue.ref_categorie AND libelle.libelle = '$category' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");    		
	$string .= "<td align=\"left\"><select name=\"production_house\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";    
        my  %OPTIONS = ();
	if ($production_house) {
		$string  .= "<option selected value=\"$production_house\" onblur=\"skipcycle=false\">$production_house</option>";
	}
        $string  .= "<option value=\"\" onblur=\"skipcycle=false\">--------</option>";    
        while(($OPTIONS{'category'})=$c->fetchrow()) {	
		$string .= "<option onblur=\"skipcycle=false\" VALUE=\"$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";
	}
        $string .= "</select>";
        $string .= "</td>";
	$string .= "</tr>";
	$string .= "<tr>";
	$string .= "<td align=\"left\">CHF min.</td><td align=\"left\"><input type=\"text\" name=\"price_min\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td>";
	$string .= "<td></td>";
	$string .= "<td align=\"left\">CHF max.</td><td align=\"left\"><input type=\"text\" name=\"price_max\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td>";
	$string .= "</tr>";
	return $string;

	return $string;	
}

sub getIsEnchereDealAgain {
    my $category = $query->param ("category");
    my $load = $query->param("isencher");
    my $name = $query->param("name");
    my $article = $query->param("article");
    my $type_ecran = $query->param("type_ecran"); 
    my $subcat= $query->param ("subcat");
    my  $string ;
    $string .="<tr>";
    $string .="<td align=\"left\"><label id=\"label_image\">$SERVER{'avec_enchere'}</label></td>";
    $string .= "<td align=\"left\"><select name=\"is_enchere\" onchange=\"go();\">";
    if ($load) {
	$string .= "<option selected value=\"$load\">$load</option>";
    }
    $string .= "<option>---------</option>";    
    $string .= "<option value=\"/cgi-bin/add_other.pl?lang=$lang&amp;page&session=$session_id&category=$category&isencher=$SERVER{'yes'}&category=$category&subcat=$subcat&type_ecran=$type_ecran&name=$name&article=$article\">$SERVER{'yes'}</option>";
    $string .= "<option value=\"/cgi-bin/add_other.pl?lang=$lang&amp;page=deal_again&session=$session_id&category=$category&isencher=$SERVER{'no'}&category=$category&subcat=$subcat&type_ecran=$type_ecran&name=$name&article=$article\">$SERVER{'no'}</option>";    
    $string .= "</select>";
    $string .= "</td></tr>";
    return $string;    
}

sub loadEncherePropertiesDealAgain {
	my $category = $query->param ("category");
	my $name = $query->param("name");
	my $enchere_long = $query->param("enchere_long");        
        my $load = $query->param("isencher");
	my $subcat = $query->param("subcat");
	my $article = $query->param("article");
	my $wine_country = $query->param("wine_country");
	my $region = $query->param("region");
        my $fabricant= $query->param("fabricant");
        my $description = $query->param("description");
	my $game_type = $query->param("game_type");
        my $price=  $query->param("price");
        my $selected = $enchere_long;
	my $string;
	$ENV{'TZ'} = 'Europe/Paris';
	tzset();
	
	my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
	my  $date = sprintf "%4d-%02d-%02d",$year+1900,$mon+1,$mday;	
	my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);	
	
	
	&Date_Init("Language=French","DateFormat=non-US","TZ=Europe/Paris"); #French Summer Time 
        my  $date2 = ParseDateString("aujourd'hui");

	my   $currentDate = $date;
	my   $cutoffDate  = &DateCalc($date, "+ $enchere_long jours");
	
	my $year2 = substr($cutoffDate,0,4);
	my $month2 = substr($cutoffDate,4,2);
	my $day2 = substr($cutoffDate,6,2);

	my $date_finish = "$year2-$month2-$day2";

	
	$string .="<tr>";
		$string .="<td align=\"left\">$SERVER{'debut_enchere_label'}</td>";
		$string .="<td align=\"left\"><input type=\"text\" name=\"enchere_date_start\" value=\"$date $time\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td>";		
	$string .="</tr>";
	$string .="<tr>";
		$string .="<td align=\"left\">$SERVER{'duree_enchere_label'}</td>";
		$string .="<td align=\"left\"><select name=\"duration_enchere\" onchange=\"go4();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
		$string .= "<option selected value=\"$selected\">$selected</option>";
		for (my $i = 1; $i < 31; $i++) {
			$string .= "<option value=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=deal_again&session=$session_id&category=$category&subcat=$subcat&isencher=$load&enchere_long=$i&wine_country=$wine_country&region=$region&name=$name&article=$article&game_type=$game_type\">$i</option>";
		}
		$string .= "</select></td>";		
	$string .="</tr>";
	$string .="<tr>";
		$string .="<td align=\"left\">$SERVER{'fin_enchere_label'}</td>";
		$string .="<td align=\"left\"><input type=\"text\" name=\"enchere_end_day\" value=\"$date_finish $time\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td>";
	$string .="</tr>";
	
	return $string;
}


sub loadBoatMenu {
    my $category = $query->param("subcat");
    $lang = $query->param("lang");
    my  ($c)= $db->sqlSelectMany("libelle.libelle",
			   "subcategorie_libelle_langue, libelle, langue",
			   "ref_categorie = 94 AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
        
    my $departement = $query->param("departement");
    my $string;
    my  %OPTIONS = ();
    $string .= "<select name=\"subcat\" onchange=\"go();\">";
    $string .= "<option>----------</option>";
    if ($category) {
	$string .= "<option selected value=\"$category\">$category</option>";
    }
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option value=\"/cgi-bin/p.pl?lang=$lang&amp;page=boat&session=$session_id&subcat=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>;";
	}
    $string .= "</select>";
    return $string;    	
}

sub loadSearchBoatCategory {
    my $category = $query->param("subcat");
    $lang = $query->param("lang");    
    my  ($c)= $db->sqlSelectMany("libelle.libelle",
			   "subcategorie_libelle_langue, libelle, langue",
			   "ref_categorie = 94 AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
        
    
    my $string;
    my  %OPTIONS = ();
    $string .= "<select name=\"subcat\" onchange=\"go2();\">";
    $string .= "<option>----------</option>";
    if ($category) {
	$string .= "<option selected value=\"$category\">$category</option>";
    }
    while(($OPTIONS{'category'})=$c->fetchrow()) {
    	$string .= "<option value=\"/cgi-bin/p.pl?lang=$lang&amp;page=boat&subcat=$OPTIONS{'category'}\&show_popup=true\">$OPTIONS{'category'}</option>";
    }
    $string .= "</select>";
    return $string;    	
}

sub loadWatchCategory {
    my $subcat = $query->param("subcat");
    $lang = $query->param("lang");
    loadLanguage();
    my  ($c)= $db->sqlSelectMany("libelle.libelle",
			   "categorie_libelle_langue, libelle,langue",
			   "(ref_categorie = 34  or ref_categorie = 35) AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");

    my $selected = $query->param("category");
    my $string = "<select name=\"category\" onchange=\"go();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("departement");
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option VALUE=\"/cgi-bin/g.pl?lang=$lang&amp;page=watch&session=$session_id&category=$OPTIONS{'category'}&subcat=$subcat\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select>";
    return $string;    
	
}

sub loadWatchSubCategory {
    my $category = $query->param("category");
    $lang = $query->param("lang");
    loadLanguage();    
    my $subcat = $query->param("subcat");
    my  ($c)= $db->sqlSelectMany("DISTINCT libelle.libelle","subcategorie_libelle_langue, libelle, langue","subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' AND subcategorie_libelle_langue.ref_categorie = (SELECT categorie_libelle_langue.ref_categorie FROM categorie_libelle_langue, libelle, langue WHERE libelle.libelle ='$category' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang')");    my $selected = $query->param("subcat");
    my $string = "$SERVER{''}<select name=\"subcat\" onchange=\"go2();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("departement");
    if ($subcat) {
	$string  .= "<option selected value=\"$subcat\">$subcat</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option VALUE=\"/cgi-bin/g.pl?lang=$lang&amp;page=watch&session=$session_id&subcat=$OPTIONS{'category'}&category=$category\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select>";
    return $string;    
	
}

sub loadSearchCarSubcategories {
    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");
	
    my $subcat = $query->param("subcategory");
    my  ($c)= $db->sqlSelectMany("libelle.libelle",
			   "subcategorie_libelle_langue, langue, libelle",
			   "ref_categorie = 5 AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my $selected = $query->param("subcategory");
    my $string = "<select name=\"subcategory\" onchange=\"go();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";            
    my  %OPTIONS = ();
  
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {	
         $string .= "<option value=\"$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";
	}
    $string .= "</select>";
    return $string;    
    
}

sub loadSearchCigaresCategories {
    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");
	
    my $category = $query->param("category");
    my $subcat = $query->param("subcat");
    my  ($c)= sqlSelectMany("libelle.libelle",
			   "subcategorie_libelle_langue, langue, libellle",
			   "ref_categorie = 20 AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my $selected = $query->param("category");
    my $string = "<select name=\"category\" onchange=\"go();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";            
    my  %OPTIONS = ();
  
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option value=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=search_cigares&amp;session=$session_id&category=$OPTIONS{'category'}&country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=with_lang_french&with_lang_italian=$with_lang_italian&amp;with_lang_german=with_lang_german&with_lang_english=$with_lang_english&page=cigares\">$OPTIONS{'category'}</option>";
	}
    $string .= "</select>";
    return $string;    
	
}

sub loadCigaresCategories {
    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");
	
    my $category = $query->param("category");
    my $subcat = $query->param("subcat");
    my  ($c)= sqlSelectMany("libelle.libelle",
			   "categorie_libelle_langue, libelle, langue",
			   "categorie_libelle_langue.ref_subcategorie = article.ref_categorie AND libelle.libelle = '$category' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
        
    my %OPTIONS = ();
    my $string;
    my $selected = $query->param("category");
    $string = "<select name=\"category\" onchange=\"go();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    while(($OPTIONS{'category'})=$c->fetchrow()) {	
         $string .= "<option value=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=cigares&amp;session=$session_id&category=$OPTIONS{'category'}&subcategory=$category&country_swiss=$country_swiss&country_france=$country_france&with_lang_french=with_lang_french&with_lang_italian=$with_lang_italian&with_lang_german=with_lang_german&with_lang_english=$with_lang_english&page=cigares\">$OPTIONS{'category'}</option>";
    }
    
    return $string;    
	
}


sub loadCigaresSubCategories {
    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");
	
    my $category = $query->param("category");
    my $subcat = $query->param("subcat");
    my  ($c)= sqlSelectMany("libelle.libelle",
			   "subcategorie_libelle_langue, libelle, langue",
			   "subcategorie_libelle_langue.ref_subcategorie = article.ref_subcategorie AND libelle.libelle = '$subcat' AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' AND subcategorie_libelle_langue.ref_categorie = (SELECT ref_categorie FROM categorie_libelle_langue, libelle, langue FROM categorie_libelle_langue, libelle, langue WHERE categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')");
        
    my %OPTIONS = ();
    my $string;
    my $selected = $query->param("subcategory");
    $string = "<select name=\"subcategory\" onchange=\"go2();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    while(($OPTIONS{'category'})=$c->fetchrow()) {	
         $string .= "<option value=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=cigares&amp;session=$session_id&category=$category&subcategory=$OPTIONS{'category'}&country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=with_lang_french&with_lang_italian=$with_lang_italian&amp;with_lang_german=with_lang_german&with_lang_english=$with_lang_english&page=cigares\">$OPTIONS{'category'}</option>";
    }
    
    return $string;    
	
}
sub loadCigaresFabricants {
    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");
	
    my $category = $query->param("category");
    my $subcat = $query->param("subcat");
    my  ($c)= sqlSelectMany("DISTINCT article.marque",
			   "article, categorie_libelle_langue, libelle, langue",
			   "categorie_libelle_langue.ref_categorie = article.ref_categorie AND libelle.libelle = '$category' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
        
    my %OPTIONS = ();
    my $string;
    $string = "$SERVER{''}<select name=\"subcat\" onchange=\"go2();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    while(($OPTIONS{'category'})=$c->fetchrow()) {	
         $string .= "<a  class=\"menulink\" class=&{ns4class} href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&category=$OPTIONS{'category'}&country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=with_lang_french&with_lang_italian=$with_lang_italian&amp;with_lang_german=with_lang_german&with_lang_english=$with_lang_english&page=cigares\">$OPTIONS{'category'}</a>&nbsp";
    }
    
    return $string;    
	
}
sub loadChocolatMenu {
    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");
	
    my $category = $query->param("category");
    my $subcat = $query->param("subcat");
    my  ($c)= sqlSelectMany("libelle.libelle",
			   "subcategorie_libelle_langue",
			   "subcategorie_libelle_langue.ref_categorie = 40 AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie.ref_langue = langue.id_langue AND langue.key = '$lang'");
        
    my  %OPTIONS = ();
    my $string;
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {	
         $string .= "<a  class=\"menulink\" class=&{ns4class} href=\"/cgi-bin/recordz.cgi?lang=$lang&page=chocolat&amp;session=$session_id&category=$OPTIONS{'category'}&country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=with_lang_french&with_lang_italian=$with_lang_italian&amp;with_lang_german=with_lang_german&with_lang_english=$with_lang_english&page=cigares\">$OPTIONS{'category'}</a>&nbsp";
    }    
    return $string;    	
}

sub loadArtCategory {
    my $u = $query->param("u");
    my  ($c)= $db->sqlSelectMany("libelle.libelle",
			   "categorie_libelle_langue, libelle,langue",
			   "ref_categorie = 0 AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my $selected = $query->param("category");
    my $string = "<select name=\"category\" onchange=\"go4();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("departement");
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option VALUE=\"/cgi-bin/a.pl?lang=$lang&amp;page=art_design&u=$u&session=$session_id&category=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select>";
    return $string;    
    
}

sub loadParfumCategory {
    my $u = $query->param("u");
    my  ($c)= $db->sqlSelectMany("libelle.libelle",
			   "categorie_libelle_langue, libelle,langue",
			   "(ref_categorie = 13 OR ref_categorie = 16) AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my $selected = $query->param("category");
    my $string = "<select name=\"category\" onchange=\"go3();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("departement");
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option VALUE=\"/cgi-bin/b.pl?lang=$lang&amp;page=parfum&u=$u&session=$session_id&category=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select>";
    return $string;    
	
}
sub loadParfumSubCategory {
    my $u = $query->param("u");
    my $category = $query->param("category");	
    my  ($c)= $db->sqlSelectMany("DISTINCT libelle.libelle","subcategorie_libelle_langue, libelle, langue","subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' AND subcategorie_libelle_langue.ref_categorie = (SELECT categorie_libelle_langue.ref_categorie FROM categorie_libelle_langue, libelle, langue WHERE libelle.libelle ='$category' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang')");
    my $selected = $query->param("subcategory");
    my $string = "<select name=\"subcategory\" onchange=\"go4();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option VALUE=\"/cgi-bin/b.pl?lang=$lang&amp;page=parfum&session=$session_id&category=$category&subcategory=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select>";
    return $string;    
	
}


sub loadArtSubCategory {
    my $u = $query->param("u");
    my $category = $query->param("category");	
    my  ($c)= $db->sqlSelectMany("DISTINCT libelle.libelle","subcategorie_libelle_langue, libelle, langue","subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' AND subcategorie_libelle_langue.ref_categorie = (SELECT categorie_libelle_langue.ref_categorie FROM categorie_libelle_langue, libelle, langue WHERE libelle.libelle ='$category' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang')");
    my $selected = $query->param("subcat");
    my $string = "<select name=\"subcat\" onchange=\"go5();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option VALUE=\"/cgi-bin/a.pl?lang=$lang&amp;page=art_design&u=$u&session=$session_id&category=$category&subcat=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select>";
    return $string;    
    
}
sub loadWatchAndJewelsByIndex {
    my  $cat = shift || '';
    my  $type = shift  || '';
    my  $depot = $query->param("depot") ;
    $depot=~ s/[^A-Za-z0-9 ]//;
    my  $index_start = $query->param ("min_index");
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index");
    $index_end =~ s/[^A-Za-z0-9 ]//;
    my $category = $query->param("category");
    my $subcat = $query->param("subcat");
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    $date = trimwhitespace($date);
    my  $string = "";
    my  $add;
    my $from;
    if ($category) {$from .= ", categorie_libelle_langue, libelle, langue";
                    $add .= " AND libelle.libelle = '$category' AND article.ref_categorie = categorie_libelle_langue.ref_categorie AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'";}
    if ($subcat) {$from .= ", subcategorie_libelle_langue";
                    $add .= " AND subcategorie_libelle_langue.id_subcategorie_libelle_langue = (SELECT libelle.libelle FROM subcategorie_libelle_langue, libelle, langue WHERE libelle.libelle = '$subcat' AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang') AND article.ref_subcategorie = subcategorie_libelle_langue.ref_subcategorie";
                    }

    
    if (!$index_start ) {
	$index_start = 0;
    }
    if (!$index_end ) {
	$index_end = 40;
    }

   $add .= getAdd();    

    my  ($c)= sqlSelectMany("DISTINCT article.nom,marque,prix, pochette,id_article,date_stock,article.ref_categorie,article.lieu,quantite",
		       "article,met_en_vente $from",
		       "ref_article = id_article  AND met_en_vente.page_principale = 'on' AND ref_statut = '3' and quantite > 0 AND  enchere_date_fin > "." '$date%' AND article.ref_categorie BETWEEN 17 AND 18 $add ORDER BY  date_stock DESC LIMIT $index_start, $index_end  ");	
    
#	$string .= "<br />";
#	$string .= "<table width=\"500\" border=\"0\">";
#	$string .= "<tr>";
#	$string .= "<td align=\"left\">&nbsp;</td>";
#	$string .=  "<td align=\"left\">&nbsp;</td>";
#	$string .=  "<td align=\"left\">&xcvxcv;xcvxc</td>";
#	$string .=  "</tr>";

    my $i = 0;
    
    my $j = 0;
    #$string .= "<hr>";
    $string .= "<table style=\"border-top-width:medium;border-top-color:#94CEFA\"><tr>";
    
    while( ($ARTICLE{'name'},$ARTICLE{'author'},$ARTICLE{'price'},$ARTICLE{'pochette'},$ARTICLE{'id_article'},$ARTICLE{'date'},$ARTICLE{'ref_categorie'},$ARTICLE{'article_lieu'},$ARTICLE{'quantity'})=$c->fetchrow()) {
	#$string .= " <label>&nbsp;&nbsp;$ARTICLE{'genre'}</label>";
	my $img;
	if ($ARTICLE{'pochette'} eq '') {
		$ARTICLE{'pochette'} = "../images/no.gif";
	}
	
	if ($ARTICLE{'date'} eq $date) {
		$img = "../images/new_article.gif"
	}else {
		##$img = "../images/blank.gif"
	}
	my $add3;
	if ($ARTICLE{'ref_categorie'} eq '11') {
		$add3 = $ARTICLE{'article_lieu'};
	}
	#$ARTICLE{'label'}
	#$ARTICLE{'label'} .= "...";

	$string .= "<td align=\"left\" width=\"253px\" height=\"100px\" style=\"background-image:url(../images/table_article_decoration.jpg);background-position:right bottom;background-repeat: no-repeat;\">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&amp;action=detailother&amp;article=$ARTICLE{'id_article'}\" class=\"menulink3\" >$ARTICLE{'name'} $add3</a><br/>&nbsp;&nbsp;&nbsp;&nbsp;<img alt=\"\" src=\"$ARTICLE{'pochette'}\" /> <img alt=\"\" src=\"$img\" /><br/>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$ARTICLE{'price'} <br/><br/></td>";
	$i += 1;
	$j += 1;

	if ($i eq 1) {
		#$string .= "<hr>";
		$string .= "<td align=\"left\" width=\"10px\"></td>";		
		$i = 0;
	}
	
	if ($j eq 2) {
		
		$string .= "</tr>";
		$string .= "<tr>";
		$string .= "</tr>";
		$string .= "<tr>";
		$string .= "</tr>";
		$string .= "<tr>";		
		$j = 0;
	}
    }    
    $string .= "</table>";
    return $string;
    
}




sub loadSearchWineCountry {
    my  ($c)= $db->sqlSelectMany("nom",
			   "pays_present",
			   "id_pays_present = id_pays_present");
    my $selected = $query->param("country");
    my $string = "<select name=\"country\" onchange=\"go4();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("departement");
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option VALUE=\"/cgi-bin/o.pl?lang=$lang&amp;page=wine&session=$session_id&country=$OPTIONS{'category'}&show_popup=true\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select>";
    return $string;    
	
}

sub loadSearchWineType {
    my $country = $query->param("country");
    my $cepage = $query->param("cepage");
    my $type = $query->param("type");
    my  ($c)= $db->sqlSelectMany("libelle.libelle",
					"type_de_vin_libelle_langue, libelle, langue",
					"type_de_vin_libelle_langue.ref_libelle = libelle.id_libelle AND type_de_vin_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    
    my $string = "<td>$SERVER{'type_de_vin'}</td><td align=\"left\"><select name=\"type\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("departement");
    if ($type) {
	$string  .= "<option selected value=\"$type\">$type</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option VALUE=\"$OPTIONS{'category'}\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select></td>";
    return $string;    
	
}

sub loadSearchWineCepage {
    my $country = $query->param("country");
    my $cepage = $query->param("cepage");
    my $type = $query->param("type");
    my  ($c)= $db->sqlSelectMany("cepage.nom",
			   "pays_region_vin,cepage",
			   "ref_pays_region_vin = id_pays_region_vin AND pays_region_vin.nom = '$country'");
    
    my $string = "<td align=\"left\">$SERVER{'cepage'}</td><td align=\"left\"><select name=\"cepage\" onchange=\"go3();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("departement");
    if ($cepage) {
	$string  .= "<option selected value=\"$cepage\">$cepage</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option VALUE=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=search_wine&type=$type&country=$country&cepage=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select></td>";
    return $string;    
	
	
}

sub loadSearchCdUsed {
	my $string;
	$string .= "<tr><td>$SERVER{'used'}</td><td>";
	my  ($c)= sqlSelectMany("libelle.libelle",
			   "etat_libelle_langue",
			   "etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.key = '$lang'");
	$string .= "<select name=\"used\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\" >";
	my  %OPTIONS = ();
	while(($OPTIONS{'category'})=$c->fetchrow()) {	
		$string .= "<option value=\"$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";
	}
	$string .= "</select></td></tr>";
	return $string;	
}
sub loadWineCountry {
    $lang = $query->param("lang");
    my  ($c)= $db->sqlSelectMany("nom",
			   "pays_region_vin",
			   "id_pays_region_vin = id_pays_region_vin");
    my $selected = $query->param("country");
    my $string = "<select name=\"country\" onchange=\"go();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("departement");
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option VALUE=\"/cgi-bin/o.pl?lang=$lang&amp;page=wine&session=$session_id&country=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select>";
    return $string;    
}

sub loadSearchWineCountryTOREMOVE {
    my  ($c)= $db->sqlSelectMany("nom",
			   "pays_present",
			   "id_pays_present = id_pays_present");
    my $selected = $query->param("country");
    my $string = "<select name=\"country\" onchange=\"go();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("departement");
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option VALUE=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=search_wine&session=$session_id&country=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select>";
    return $string;    
}

sub loadWineType {
    $lang = $query->param("lang");
    my  ($c)= $db->sqlSelectMany("libelle.libelle",
			   "type_de_vin_libelle_langue, libelle, langue",
			   "type_de_vin_libelle_langue.ref_libelle = libelle.id_libelle AND type_de_vin_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my $selected = $query->param("wine_type");
    my $country = $query->param("country");
    my $cepage = $query->param("cepage");
    my $string = "<select name=\"wine_type\" onchange=\"go2();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("departement");
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {	
         $string .= "<option VALUE=\"/cgi-bin/o.pl?lang=$lang&amp;page=wine&session=$session_id&country=$country&cepage=$cepage&wine_type=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>" ;
	}
    $string .= "</select>";
    return $string;    
}

sub loadAutoFabricant {

    my $fabricant = $query->param("fabricant");
    my $withclim = $query->param("withclim");
    my $type = $query->param("type");
    my $motorisation = $query->param("motorisation");    
    my  ($c)= sqlSelectMany("DISTINCT marque",
			   "article",
			   "ref_categorie = 8");
    
    my $string = "<select name=\"fabricant\" onchange=\"go();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    
    my  %OPTIONS = ();

    if ($fabricant) {
	$string  .= "<option selected value=\"$fabricant\" onblur=\"skipcycle=false\">$fabricant</option>";
    }
    $string  .= "<option value=\"\" onblur=\"skipcycle=false\">--------</option>";
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option onblur=\"skipcycle=false\" VALUE=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=search_auto&session=$session_id&fabricant=$OPTIONS{'category'}&type=$type&withclim=$withclim&motorisation=$motorisation\">$OPTIONS{'category'}</option>";
	}
    $string .= "</select>";
    return $string;    
	
}

sub loadSearchCarFabricant {
    my $string;
    $string .= "<td>$SERVER{'fabricant'}</td><td><select name=\"fabricant\">";
    my  ($c)= $db->sqlSelectMany("DISTINCT marque",
			   "article",
			   "ref_categorie = 5");
    my  %OPTIONS = ();
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	$string .= "<option value=\"$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";
    }
    $string .= "</select></td>";
    return $string;
    
}
sub loadAutoSearchProperties {
	my $fabricant = $query->param ("fabricant");
	my $motorisation = $query->param("motorisation");
	my $withclim = $query->param("withclim");
	my $type  = $query->param ("type");
	my $string;
		$string .= "<td align=\"left\">Ann&eacute;e fabrication min</td><td align=\"left\" ><input type=\"number\" step=\"1\" name=\"year_fabrication_min\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td>";
		$string .= "<td align=\"left\">Ann&eacute;e fabrication max</td><td align=\"left\"><input type=\"number\" step=\"1\"  name=\"year_fabrication_max\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td>";	
	$string .= "</tr>";
	
	$string .= "<tr>";
		$string .= "<td align=\"left\">Nbr de cheveaux min</td><td align=\"left\"><input type=\"number\" step=\"1\" name=\"horse_nbr_min\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td>";
		$string .= "<td align=\"left\">Nbr de cheveaux max</td><td align=\"left\"><input type=\"number\" step=\"1\" name=\"horse_nbr_max\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td>";
	$string .= "</tr>";
	$string .= "<tr>";
		$string .= "<td align=\"left\">Km min</td><td align=\"left\"><input type=\"number\" step=\"1\" name=\"km_min\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"\></td>";
		$string .= "<td align=\"left\">Km max</td><td align=\"left\"><input type=\"number\" type=\"number\" step=\"1\"name=\"km_max\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td>";	
	$string .= "</tr>";

	$string .= "<tr>";
		$string .= "<td align=\"left\">$SERVER{'nb_cylindre_min'}</td><td align=\"left\"><input type=\"number\" step=\"1\" name=\"cylindre_min\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"\"></td>";
		$string .= "<td align=\"left\">$SERVER{'nb_cylindre_max'}</td><td align=\"left\"><input type=\"number\" step=\"1\" name=\"cylindre_max\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td>";	
	$string .= "</tr>";
	
	$string .= "<tr>";
		$string .= "<td align=\"left\">CHF min,</td><td align=\"left\"><input type=\"number\" step=\"1\" name=\"price_min\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td>";
		$string .= "<td align=\"left\">CHF max,</td><td align=\"left\"><input type=\"number\" step=\"1\" name=\"price_max\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td>";
	$string .= "</tr>";

	$string .= "<tr>";
		#$string .= "<td align=\"left\">Boite de vitesse</td><td align=\"left\"><input type=\"text\" name=\"price_min\" onblur=\"skipcycle=false\"></td>";
		#$string .= "<td align=\"left\">CHF max</td><td align=\"left\"><input type=\"text\" name=\"price_max\" onblur=\"skipcycle=false\"></td>";
	$string .= "</tr>";
	$string .= "<tr>";
			$string .= "<td align=\"left\">Avec clim</td>";			
			$string .= "<td align=\"left\"><select name=\"withclim\" onchange=\"go3();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">"; 
			if ($withclim) {
				$string  .= "<option selected value=\"$withclim\" onblur=\"skipcycle=false\">$withclim</option>";
			}
			$string .= "<option value =\"\">---------</option>";    
			$string .= "<option value=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=search_auto&session=$session_id&withclim=$SERVER{'yes'}&fabricant=$fabricant&type=$type&motorisation=$motorisation\">$SERVER{'yes'}</option>";
			$string .= "<option value=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=search_auto&session=$session_id&withclim=$SERVER{'no'}&fabricant=$fabricant&type=$type&motorisation=$motorisation\">$SERVER{'no'}</option>";    
			$string .= "</select>";
			$string .= "</td>";
			$string .= "<td align=\"left\">Motorisation</td>";			
			$string .= "<td align=\"left\"><select name=\"motorisation\" onchange=\"go4();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">"; 
			if ($motorisation) {
				$string  .= "<option selected value=\"$motorisation\" onblur=\"skipcycle=false\">$motorisation</option>";
			}
			$string .= "<option value =\"\">---------</option>";    
			$string .= "<option value=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=search_auto&session=$session_id&withclim=$withclim&fabricant=$fabricant&type=$type&motorisation=$SERVER{'essence'}\">$SERVER{'essence'}</option>";
			$string .= "<option value=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=search_auto&session=$session_id&withclim=$withclim&fabricant=$fabricant&type=$type&motorisation=$SERVER{'diesel'}\">$SERVER{'diesel'}</option>";
			$string .= "<option value=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=search_auto&session=$session_id&withclim=$withclim&fabricant=$fabricant&type=$type&motorisation=$SERVER{'hybride'}\">$SERVER{'hybride'}</option>";
			$string .= "<option value=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=search_auto&session=$session_id&withclim=$withclim&fabricant=$fabricant&type=$type&motorisation=$SERVER{'electrique'}\">$SERVER{'electrique'}</option>";    
			$string .= "</select>";
			$string .= "</td>";


	$string .= "</tr>";
	$string .= "<tr><td>$SERVER{'used'}</td><td>";
	my  ($c)= $db->sqlSelectMany("libelle.libelle",
			   "etat_libelle_langue, libelle, langue",
			   "etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
	$string .= "<select name=\"used\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\" >";
	my  %OPTIONS = ();
	while(($OPTIONS{'category'})=$c->fetchrow()) {	
		$string .= "<option value=\"$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";
	}
	$string .= "</select></td></tr>";
	return $string;
}

sub loadMotoFabricant {
    my $category = $query->param("category");
    my $fabricant = $query->param("fabricant");
    my $withclim = $query->param("withclim");
    my $type = $query->param("type");
    my $motorisation = $query->param("motorisation");    
    my  ($c)= $db->sqlSelectMany("DISTINCT marque",
			   "article",
			   "article.ref_categorie = 6");
    
    my $string = "<select name=\"fabricant\"  onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    
    my  %OPTIONS = ();

    if ($fabricant) {
	$string  .= "<option selected value=\"$fabricant\" onblur=\"skipcycle=false\">$fabricant</option>";
    }
    $string  .= "<option value=\"\" onblur=\"skipcycle=false\">--------</option>";
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option onblur=\"skipcycle=false\" VALUE=\"$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";
	}
    $string .= "</select>";
    return $string;    
	
}
sub loadSearchMotoCategory {
    $lang = $query->param("lang");
    loadLanguage();    
    my $fabricant = $query->param("fabricant");
    my $category = $query->param("category");
    my $withclim = $query->param("withclim");
    my $motorisation = $query->param("motorisation");
    my $type = $query->param("type");	    
    my  ($c)= sqlSelectMany("libelle.libelle",
			   "categorie_libelle_langue, libelle, langue",
			   "id_categorie BETWEEN 37 AND 39 AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    
    my $string = "<select name=\"category\" onchange=\"go();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\" >";
    
    my  %OPTIONS = ();

    if ($category) {
	$string  .= "<option  onblur=\"skipcycle=false\" selected value=\"$category\">$category</option>";
    }
    $string  .= "<option onblur=\"skipcycle=false\" value=\"\">--------</option>";
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option onblur=\"skipcycle=false\" VALUE=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=search_moto&session=$session_id&fabricant=$fabricant&category=$OPTIONS{'category'}&withclim=$withclim&motorisation=$motorisation\">$OPTIONS{'category'}</option>";
	}
    $string .= "</select>";
    return $string;    
	
}

sub loadSearchMotoSubCategories {
    $lang = $query->param("lang");
    loadLanguage();    
    my $fabricant = $query->param("fabricant");
    my $category = $query->param("category");
    my $subcat = $query->param("subcat");
    my $motorisation = $query->param("motorisation");
    my $type = $query->param("type");	    
    my  ($c)= $db->sqlSelectMany("libelle.libelle",
			   "subcategorie_libelle_langue, libelle, langue",
			   "ref_categorie = 6 and subcategorie_libelle_langue.ref_libelle = libelle.id_libelle and subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
    
    my $string = "<select name=\"subcat\" onchange=\"go3();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\" >";
    
    my  %OPTIONS = ();

    if ($subcat) {
	$string  .= "<option  onblur=\"skipcycle=false\" selected value=\"$subcat\">$subcat</option>";
    }
    $string  .= "<option onblur=\"skipcycle=false\" value=\"\">--------</option>";
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option onblur=\"skipcycle=false\" VALUE=\"/cgi-bin/j.pl?lang=$lang&amp;page=moto&show_popup=true&$session_id&category=$category&subcat=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";
	}
    $string .= "</select>";
    return $string;    
	
}

sub loadMotoSearchProperties {
    $lang = $query->param("lang");
    loadLanguage();    
	my $fabricant = $query->param ("fabricant");
	my $motorisation = $query->param("motorisation");
	my $withclim = $query->param("withclim");
	my $type  = $query->param ("type");
	my $string;
		$string .= "<td align=\"left\">Ann�e fabrication min</td><td align=\"left\" ><input type=\"number\" step=\"1\" name=\"year_fabrication_min\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td>";
		$string .= "<td align=\"left\">Ann�e fabrication max</td><td align=\"left\"><input type=\"number\" step=\"1\" name=\"year_fabrication_max\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td>";	
	$string .= "</tr>";
	
	$string .= "<tr>";
		$string .= "<td align=\"left\">Km min</td><td align=\"left\"><input type=\"number\" step=\"1\" name=\"km_min\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"\"></td>";
		$string .= "<td align=\"left\">Km max</td><td align=\"left\"><input type=\"number\" step=\"1\" name=\"km_max\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td>";	
	$string .= "</tr>";

	
	$string .= "<tr>";
		$string .= "<td align=\"left\">CHF min,</td><td align=\"left\"><input type=\"number\" step=\"1\" name=\"price_min\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td>";
		$string .= "<td align=\"left\">CHF max,</td><td align=\"left\"><input type=\"number\" step=\"1\" name=\"price_max\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td>";
	$string .= "</tr>";

	$string .= "<tr><td>$SERVER{'used'}</td><td>";
	my  ($c)= $db->sqlSelectMany("libelle.libelle",
			   "etat_libelle_langue,libelle,langue",
			   "etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
	$string .= "<select name=\"used\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\" >";
	my  %OPTIONS = ();
	while(($OPTIONS{'category'})=$c->fetchrow()) {	
		$string .= "<option value=\"$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";
	}
	$string .= "</select></td></tr>";
	return $string;
}

sub loadTvOrDVD {
    $lang = $query->param("lang");
    loadLanguage();
    
    my $category = $query->param("subcat");
    my  ($c)= $db->sqlSelectMany("libelle.libelle",
			   "subcategorie_libelle_langue, libelle, langue",
			   "subcategorie_libelle_langue.ref_categorie = '7' AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
  
    my  $string;
    $string .= "<select name=\"subcat\" onchange=\"go();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";    
    $string .= "<option>---------</option>";
    if ($category) {
	$string .= "<option selected value=\"$category\">$category</option>";	
    }
    my  %OPTIONS = ();
    while(($OPTIONS{'category'})=$c->fetchrow()) {	
         $string .= "<option value=\"/cgi-bin/q.pl?lang=$lang&amp;page=tv_video&session=$session_id&subcat=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";
	}
    $string .="</select>";
    return $string;
}

sub loadTvTypeEcran {
    my $category = $query->param ("category");
    my $subcat= $query->param ("subcat");
    my $load = $query->param("isencher");
    my $fabricant = $query->param("fabricant");
    my $type_ecran = $query->param("type_ecran");
    $lang = $query->param("lang");
    loadLanguage();

    my  ($c)= sqlSelectMany("libelle.libelle",
			   "type_ecran_libelle_langue, libelle, langue",
			   "type_ecran_libelle_langue,ref_libelle = libelle.id_libelle AND type_ecran_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
  
    my  $string ;
    $string .= "<td align=\"left\">$SERVER{'type_ecran'}</td>";
    $string .= "<td align=\"left\">";
    $string .= "<select name=\"type_ecran\" onchange=\"go2();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";    
    $string .= "<option value=\"\">---------</option>";
    if ($type_ecran) {
	$string .= "<option selected value=\"$type_ecran\">$type_ecran</option>";	
    }
    my  %OPTIONS = ();
    while(($OPTIONS{'category'})=$c->fetchrow()) {	
         $string .= "<option value=\"/cgi-bin/q.pl?lang=$lang&amp;page=search_tv&session=$session_id&category=$category&isencher=$load&subcat=$subcat&type_ecran=$OPTIONS{'category'}&fabricant=$fabricant\">$OPTIONS{'category'}</option>";
	}
    $string .= "</select>";
    $string .= "</td>";
    
    return $string;    

}
sub loadTvFabricant {
    $lang = $query->param("lang");
    loadLanguage();

    my $category = shift || '';
    my $fabricant = $query->param("fabricant");
    my $type_ecran = $query->param("type_ecran");

    my  ($c)= sqlSelectMany("DISTINCT marque",
			   "article,subcategorie_libelle_langue, libelle, langue",
			   "article.ref_subcategorie = subcategorie_libelle_langue.ref_subcategorie AND libelle.libelle = '$category' AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
  
    my  $string ;
    $string .= "<td align=\"left\">$SERVER{'fabricant'}</td>";
    $string .= "<td align=\"left\">";
    $string .= "<select name=\"fabricant\" onchange=\"go3();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";    
    $string .= "<option value=\"\">---------</option>";
    if ($fabricant) {
	$string .= "<option selected value=\"$fabricant\">$fabricant</option>";	
    }
    my  %OPTIONS = ();
    while(($OPTIONS{'category'})=$c->fetchrow()) {	
         $string .= "<option value=\"/cgi-bin/q.pl?lang=$lang&amp;page=search_tv&session=$session_id&category=$category&t&fabricant=$OPTIONS{'category'}&type_ecran=$type_ecran\">$OPTIONS{'category'}</option>";
	}
    $string .= "</select>";
    $string .= "</td>";
    
    return $string;    
	
}

sub loadSearchTvSubCategories {
    $lang = $query->param("lang");
    loadLanguage();
    my $subcategory = $query->param("subcategory");
    my $string;
    $string .= "<td>$SERVER{'subcategory'}</td><td><select name=\"subcategory\" onchange=\"go2()\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\" >";
    my  ($c)= $db->sqlSelectMany("libelle.libelle",
			   "subcategorie_libelle_langue, libelle, langue",
			   "subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' and subcategorie_libelle_langue.ref_categorie = 7");
    $string .= "<option>----------</option>";
    if ($subcategory) {
	$string .= "<option selected value=\"$subcategory\">$subcategory</option>";
    }
    my  %OPTIONS = ();
    while(($OPTIONS{'category'})=$c->fetchrow()) {	
	$string .= "<option value=\"/cgi-bin/q.pl?page=tv_video&show_popup=true&subcategory=$OPTIONS{'category'}&lang=$lang\">$OPTIONS{'category'}</option>";
    }
    $string .= "</select></td>";

    return $string;
}


sub loadSearchTvTypeEcran {
    $lang = $query->param("lang");
    loadLanguage();
    my $type_ecran = $query->param("type_ecran");
    my $subcategory = $query->param("subcategory");
    my $string;
    $string .= "<td>$SERVER{'type_ecran'}</td><td><select name=\"type_ecran\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\" >";
    $string .= "<option>----------</option>";
    if ($type_ecran) {
	$string .= "<option selected value=\"$type_ecran\">$type_ecran</option>";
    }
    $string .= "<option value=\"$SERVER{'lcd'}\">$SERVER{'lcd'}</option>";
    $string .= "<option value=\"$SERVER{'plasma'}\">$SERVER{'plasma'}</option>";
    $string .="</select><td>";

}

sub loadSearchLecteurDvdType {
    $lang = $query->param("lang");
    loadLanguage();
    my $subcategory = $query->param("subcategory");
    my $fabricant = $query->param("fabricant");
    my $dvd_type = $query->param("dvd_type");
    my $string;
    $string .= "<td>$SERVER{'dvd_type'}</td><td><select name=\"dvd_type\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\" >";
    $string .= "<option>----------</option>";
    if ($dvd_type) {
	$string .= "<option selected value=\"$dvd_type\">$dvd_type</option>";
    }
    my  ($c)= $db->sqlSelectMany("libelle.libelle",
			   "libelle,type_ecran_libelle_langue",
			   "type_ecran_libelle_langue.ref_libelle = libelle.id_libelle AND type_ecran_libelle_langue.ref_langue = langue.id_langue AND libelle.libelle = '$dvd_type' AND langue.key = '$lang'");
    my  %OPTIONS = ();
    while(($OPTIONS{'category'})=$c->fetchrow()) {	
    	$string .= "<option value=\"$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";
    }
    $string .= "</select></td>";

}


sub loadSearchTvFabricant {
    my $string;
    my $type_ecran = $query->param("type_ecran");
    my $subcategory = $query->param("subcategory");
    my $fabricant = $query->param("fabricant");
    $string .= "<td>$SERVER{'fabricant'}</td><td><select name=\"fabricant\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\" >";
    $string .= "<option>----------</option>";
    if ($fabricant) {
	$string .= "<option selected value=\"$fabricant\">$fabricant</option>";
    }
    my  ($c)= $db->sqlSelectMany("DISTINCT marque",
			   "article",
			   "article.ref_categorie = 7 and article.ref_subcategorie = (SELECT ref_subcategorie FROM subcategorie_libelle_langue, libelle, langue WHERE subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND libelle.libelle = '$subcategory' AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')");
    my  %OPTIONS = ();
    while(($OPTIONS{'category'})=$c->fetchrow()) {	
    	$string .= "<option value=\"$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";
    }
    $string .= "</select></td>";

}

sub loadLecteurMp3Properties {
	my $string;
	$string .= "<tr>";
	$string .= "<td align=\"left\">$SERVER{'capacite_min'}</td><td align=\"left\"><input type=\"text\" name=\"capacite_min\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td>";
	$string .= "<td align=\"left\">$SERVER{'capacite_max'}</td><td align=\"left\"><input type=\"text\" name=\"capacite_max\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td>";
	$string .= "</tr>";
	return $string;    
}
sub loadSearchTvProperties {
	my $string;
	$string .= "<td align=\"left\">$SERVER{'ecran_size_min'}</td><td align=\"left\"><input type=\"text\" name=\"tv_size_min\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td>";
	$string .= "<td align=\"left\">$SERVER{'ecran_size_max'}</td><td align=\"left\"><input type=\"text\" name=\"tv_size_max\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td>";
	$string .= "</tr>";
	$string .= "<tr>";
	$string .= "<td align=\"left\">CHF min</td><td align=\"left\"><input type=\"text\" name=\"price_min\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td>";
	$string .= "<td align=\"left\">CHF max</td><td align=\"left\"><input type=\"text\" name=\"price_max\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td>";
	$string .= "</tr>";
	$string .= "<tr><td>$SERVER{'used'}</td><td>";
	my  ($c)= $db->sqlSelectMany("libelle.libelle",
			   "etat_libelle_langue, libelle, langue",
			   "etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
	$string .= "<select name=\"used\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\" >";
	my  %OPTIONS = ();
	while(($OPTIONS{'category'})=$c->fetchrow()) {	
		$string .= "<option value=\"$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";
	}
	$string .= "</select></td></tr>";
	
	return $string;
}

sub loadSearchLecteurProperties {
	my $string;
	$string .= "<tr>";
	$string .= "<td align=\"left\">CHF min</td><td align=\"left\"><input type=\"text\" name=\"price_min\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td>";
	$string .= "<td align=\"left\">CHF max</td><td align=\"left\"><input type=\"text\" name=\"price_max\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></td>";
	$string .= "</tr>";
	$string .= "<tr><td>$SERVER{'used'}</td><td>";
	my  ($c)= $db->sqlSelectMany("libelle.libelle",
			   "etat_libelle_langue, libelle, langue",
			   "etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
	$string .= "<select name=\"used\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\" >";
	my  %OPTIONS = ();
	while(($OPTIONS{'category'})=$c->fetchrow()) {	
		$string .= "<option value=\"$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";
	}
	$string .= "</select></td></tr>";
	
	return $string;
}

sub loadLocationVilla {
	my $string;
	$string .= "<tr>";
	$string .= "<td align=\"left\">$SERVER{'city_label'}</td>";
	$string .= "<td align=\"left\"><input type=\"text\" name=\"place\"></td>";
	$string .= "</tr>";
	return $string;
}

sub localNbrFloor {
	my $string;
	$string .= "<tr>";
	$string .= "<td align=\"left\">$SERVER{'nbr_piece'}</td>";
	$string .= "<td align=\"left\"><input type=\"text\" name=\"nbr_piece\"></td>";
	$string .= "</tr>";
	return $string;
}

sub localHabitableSurface {
	my $string;
	$string .= "<tr>";
	$string .= "<td align=\"left\">$SERVER{'habitable_surface_min'}</td>";
	$string .= "<td align=\"left\"><input type=\"text\" name=\"habitable_surface_min\"></td>";
	$string .= "<td align=\"left\">$SERVER{'habitable_surface_max'}</td>";
	$string .= "<td align=\"left\"><input type=\"text\" name=\"habitable_surface_min\"></td>";
	$string .= "</tr>";
	return $string;
}


sub loadBuyOrLocationForWish {
	my $string;
	my $category = $query->param ("category");
	$string .= "<tr>";
	$string .= "<td align=\"left\">$SERVER{'label_location_or_buy'}</td>";
	$string .= "<td align=\"left\"><select name=\"location_or_buy\" onchange=\"go4()\">";
	$string .= "<option value=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=add_wish&session=$session_id&category=$category&\">$SERVER{'location'}</option>";
	$string .= "<option value=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=add_wish&session=$session_id&category=$category&\">$SERVER{'buy'}</option></td>";
	$string .= "</tr>";
	return $string;
}

sub getCategoryGoAddWish {
    my $load = $query->param("isencher");
    my  ($c)= sqlSelectMany("libelle.libelle",
			   "categorie_libelle_langue, libelle, langue",
			   "categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my $selected = $query->param("category");
    my  $string = "<option selected value=\"$selected\">$selected</option>";
    my  %OPTIONS = ();
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option VALUE=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=add_wish&isencher=$load&session=$session_id&category=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>" ;
	}
    return $string;    
}


sub loadImmobilierMenu {
    my $canton = $query->param("canton");
    my $country = $query->param("country_name");
    my $location_type = $query->param("location_type");
    my $location_ou_achat = $query->param("location_ou_achat");
    my $subcategory = $query->param("subcategory");
    my $departement = $query->param("departement");
    my $selected;
    my $string = "<select name=\"subcategory\" onchange=\"go2();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my  ($c)= $db->sqlSelectMany("libelle.libelle","subcategorie_libelle_langue,libelle, langue","subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' AND subcategorie_libelle_langue.ref_subcategorie = (SELECT ref_subcategorie FROM subcategorie_libelle_langue WHERE ref_categorie = 25 AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')");
    $string .= "<option>--------</option>";
    if ($subcategory) {
	$string .= "<option selected value=\"$subcategory\">$subcategory</option>";	
    }

    while( ($ARTICLE{'genre'})=$c->fetchrow()) {
	$string .= "<option value=\"/cgi-bin/immo.pl?lang=$lang&amp;page=immo&session=$session_id&canton=$canton&country_name=$country&location_type=$location_type&subcategory=$ARTICLE{'genre'}&location_ou_achat=$location_ou_achat&location_type=$location_type\">$ARTICLE{'genre'}</option>";
    }
    $string .= "</select>";
    return $string;
}

sub loadSearchImmobilierMenu {
    my $canton = $query->param("canton");
    my $country = $query->param("country_name");
    my $location_type = $query->param("location_type");
    my $location_ou_achat = $query->param("location_ou_achat");
    my $subcategory = $query->param("subcategory");
    my $departement = $query->param("departement");
    my $selected;
    my $string = "<select name=\"subcategory\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my  ($c)= $db->sqlSelectMany("libelle.libelle","subcategorie_libelle_langue,libelle, langue","subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' AND subcategorie_libelle_langue.ref_subcategorie = (SELECT ref_subcategorie FROM subcategorie_libelle_langue WHERE ref_categorie = 25 AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')");
    $string .= "<option>--------</option>";
    if ($subcategory) {
	$string .= "<option selected value=\"$subcategory\">$subcategory</option>";	
    }

    while( ($ARTICLE{'genre'})=$c->fetchrow()) {
	$string .= "<option value=\"$ARTICLE{'genre'}\">$ARTICLE{'genre'}</option>";
    }
    $string .= "</select>";
    return $string;
}

sub loadImmobilierLocationType {
    my $subcat = $query->param("subcat");
    my $canton = $query->param("canton");
    my $location = $query->param("location_type");
    my $country = $query->param("country");    

    my  $string .= "";
    
    my  ($c)= sqlSelectMany("libelle.libelle","location_ou_achat_libelle_langue, libelle, langue","location_ou_achat_libelle_langue.ref_libelle = libelle.id_libelle AND location_ou_achat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    $string .= "<select name=\"location_type\" onchange=\"go2();\">";
    $string .= "<option value=\"\">-------</option>";
    if ($location) {
	$string .= "<option selected value=\"$location\">$location</option>";	
    }
    
    while( ($ARTICLE{'genre'})=$c->fetchrow()) {
	$string .= "<option value=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=immo&amp;type=6&session=$session_id&canton=$canton&subcat=$subcat&location_type=$ARTICLE{'genre'}&country=$country\">$ARTICLE{'genre'}</option>";
    }
    $string .="</select>";
    return $string;
}

sub loadCantonImmoMain {
	my $subcat = $query->param("subcat");
	my $canton = $query->param("canton");
	my $location_type = $query->param("location_type");
	my $string;
        my  ($c)= sqlSelectMany("nom","canton_$lang","");
	$string .= "<select name=\"canton\" onchange=\"go4();\">";
	$string .= "<option value=\"\">-------</option>";
    if ($canton) {
	$string .= "<option selected value=\"$canton\">$canton</option>";	
    }
    my  %OPTIONS = ();
    while(($OPTIONS{'category'})=$c->fetchrow()) {	
         $string .= "<option value=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=immo&session=$session_id&location_type=$location_type&subcat=$subcat&canton=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";
	}
    $string .= "</select>";
return $string;	


}

sub loadSearchAstroCategories {
    my  ($c)= $db->sqlSelectMany("libelle.libelle",
			   "categorie_libelle_langue, langue, libelle",
			   "ref_categorie = 32 AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my $selected = $query->param("category");
    my $string = "<td>$SERVER{'category'}</td><td><select name=\"category\" onchange=\"go();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("departement");
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option VALUE=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=search_astro&amp;session=$session_id&category=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";
	}
    $string .= "</select></td>";
    return $string;    
	
}

sub loadSearchAnimalCategories {
    $lang = $query->param("lang");
    my  ($c)= $db->sqlSelectMany("libelle.libelle",
			   "categorie_libelle_langue, langue, libelle",
			   "ref_categorie = 33 AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my $selected = $query->param("category");
    my $string = "<td>$SERVER{'category'}</td><td><select name=\"category\" onchange=\"go6();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("departement");
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option VALUE=\"/cgi-bin/f.pl?lang=$lang&amp;page=animal&amp;session=$session_id&category=$OPTIONS{'category'}&show_popup=true\">$OPTIONS{'category'}</option>";
	}
    $string .= "</select></td>";
    return $string;    
	
    
}
sub loadSearchAstroSubCategories {
    my $category = $query->param("category");
    my  ($c)= $db->sqlSelectMany("libelle.libelle",
			   "subcategorie_libelle_langue, langue, libelle",
			   "ref_categorie = 32 AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my $selected = $query->param("subcategory");
    my $string = "<td>$SERVER{'subcategory'}</td><td><select name=\"subcategory\" onchange=\"go2();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("departement");
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option VALUE=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=search_astro&amp;session=$session_id&subcategory=$OPTIONS{'category'}&category=$category\">$OPTIONS{'category'}</option>";
	}
    $string .= "</select></td>";
    return $string;    
	
}

sub loadSearchAnimalSubCategories {
    $lang = $query->param("lang");
    my $category = $query->param("category");
    my  ($c)= $db->sqlSelectMany("libelle.libelle",
			   "subcategorie_libelle_langue, langue, libelle",
			   "ref_categorie = 33 AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my $selected = $query->param("subcategory");
    my $string = "<td>$SERVER{'subcategory'}</td><td><select name=\"subcategory\" onchange=\"go7();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("departement");
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option VALUE=\"/cgi-bin/f.pl?lang=$lang&amp;page=animal&show_popup=true&amp;session=$session_id&subcategory=$OPTIONS{'category'}&category=$category\">$OPTIONS{'category'}</option>";
	}
    $string .= "</select></td>";
    return $string;    
	
}

sub loadSearchBookCategories {
    my  ($c)= $db->sqlSelectMany("libelle.libelle",
			   "subcategorie_libelle_langue, langue, libelle",
			   "ref_categorie = 9 AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my $selected = $query->param("category");
    my $string = "<select name=\"category\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("departement");
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option VALUE=\"$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";
	}
    $string .= "</select>";
    return $string;    
	
}
sub loadSearchBookProperties {
	my $string;
	$string .= "<tr><td>$SERVER{'title'}</td><td><input type=\"text\" name=\"title\"></td></tr><tr>";
	$string .= "<td>$SERVER{'autor'}</td><td><input type=\"text\" name=\"author\"></td></tr><tr><td>$SERVER{'year'}</td><td>	<input type=\"text\" name=\"year\"></td></tr><tr>";
	$string .= "<td>$SERVER{'editor'}</td><td><input type=\"text\" name=\"editor\"></td></tr><tr><td>$SERVER{'price_min'}</td><td><input type=\"text\" name=\"price_min\"></td><td>$SERVER{'price_max'}</td><td><input type=\"text\" name=\"price_max\"></td></tr>";

	return $string;
}


sub getArticleCat {
	my $string = "";
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;cat=hardstyle&amp;type=1&session=$session_id;\" class=\"menulink\" >Hardstyle</a>&nbsp;";
	$string .=  "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;cat=hardcore&amp;type=1&session=$session_id;\" class=\"menulink\" >Hardcore</a>&nbsp;";	
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;cat=tek&amp;type=1&session=$session_id;\" class=\"menulink\" >Techno</a>&nbsp;";	
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;cat=house&amp;type=1&session=$session_id\" class=\"menulink\" >House</a>&nbsp;";			
	$string .=  "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;cat=trance&amp;type=1&session=$session_id;\" class=\"menulink\" >Trance</a>&nbsp;";
	$string .=  "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;cat=hiphop&amp;type=1&session=$session_id;\" class=\"menulink\" >Hip Hop</a>&nbsp;";
	$string .=  "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;cat=dancehall&amp;type=1&session=$session_id;\" class=\"menulink\" >Dancehall</a>&nbsp;";
	$string .=  "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=mix_tape&amp;type=5&session=$session_id\" class=\"menulink\" >Mix Tape</a>";	
	return $string;

}

sub getNatelType {
             
    my  $string .= "";
    my  ($c)= sqlSelectMany("libelle.libelle","subcategorie_libelle_langue, libelle, langue","ref_categorie = '10' AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    
    while( ($ARTICLE{'genre'})=$c->fetchrow()) {
	$string .= "<a class=\"menulink\" class=&{ns4class} href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=informatique&amp;type=6&session=$session_id&subcat=$ARTICLE{'genre'}\">$ARTICLE{'genre'}</a>&nbsp;&nbsp;";
    }
    $string .= "</select>";
    return $string;
	
}
sub getTvVideoType {
    my  $selected = $query->param("subcat");
    my $string = "<select name=\"subcat\" onchange=\"go();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("category");
    if ($selected) {
	$string  .= "<option selected value=\"$selected\">$selected</option>";
    }
    $string  .= "<option value=\"\">--------</option>";
    my  ($c)= sqlSelectMany("libelle.libelle","subcategorie_libelle_langue,libelle, langue","subcategorie_libelle_langue.ref_categorie = '12' AND subcategorie_libelle_langue.ref_libelle = libelle.ref_libelle AND subcategorie_libelle_langue.ref_langue AND langue.key = '$lang'");
    
    while( ($ARTICLE{'genre'})=$c->fetchrow()) {
	$string .= "<option value=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=tv_video&amp;type=6&session=$session_id&subcat=$ARTICLE{'genre'}\">$ARTICLE{'genre'}</option>";
    }
    $string .= "</select>";
    return $string;
	
}

sub getInformatiqueType {
    my $category = $query->param("subcat");         
    my  $string .= "";
    my  ($c)= sqlSelectMany("libelle.libelle","subcategorie_libelle_langue,libelle, langue","subcategorie_libelle_langue.ref_categorie = '10' AND subcategorie_libelle_langue.ref_libelle = libelle.ref_libelle AND subcategorie_libelle_langue.ref_langue AND langue.key = '$lang'");
    $string .= "<select name=\"subcat\" onchange=\"go();\">";
    $string .= "<option selected value=\"$category\">$category</option>";
    while( ($ARTICLE{'genre'})=$c->fetchrow()) {
	$string .= "<option value=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=informatique&amp;type=6&session=$session_id&subcat=$ARTICLE{'genre'}\">$ARTICLE{'genre'}</option>";
    }
    $string .= "</select>";
    return $string;
	
}

sub getAutoType {
    my $category = $query->param("subcat");
    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");         
    
    my  ($c)= sqlSelectMany("libelle.libelle","subcategorie_libelle_langue, libelle, langue","subcategorie_libelle_langue.ref_categorie = '8' AND subcategorie_libelle_langue.ref_libelle = libelle.ref_libelle AND subcategorie_libelle_langue.ref_langue AND langue.key = '$lang'");
    my $string = "<select name=\"subcat\" onchange=\"go();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    $string .= "<option>-----</option>";
    if ($category) {$string .= "<option selected value=\"$category\">$category</option>";}
    while( ($ARTICLE{'genre'})=$c->fetchrow()) {
	$string .= "<option value=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=auto&amp;type=6&session=$session_id&subcat=$ARTICLE{'genre'}&country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=with_lang_french&with_lang_italian=$with_lang_italian&amp;with_lang_german=with_lang_german&with_lang_english=$with_lang_english\">$ARTICLE{'genre'}</option>";
    }
    $string .= "</select>";
    return $string;
	
}
#load html label

#load error label
loadError();

sub loadLanguage {
	if (defined $query) { 
		$lang = $query->param("lang");
		#$lang = substr ($ENV{'HTTP_ACCEPT_LANGUAGE'},0,2);
		#$lang =~ s/[^A-Za-z0-9 ]//;
		$lang = lc ($lang);
		open (FILE, "<$dirLang/$lang.conf") or die "cannot open file $dirLang/$lang.conf";    
		
		while (<FILE>) {
		(my  $label, my  $value) = split(/=/);
		$SERVER{$label} = $value;
		}
		close (FILE);
	}
}



sub loadError {
    if (defined $query) { 
		$lang = lc ($query->param('lang'));#=~ s/[^A-Za-z0-9 ]//;
		#$lang=~ s/[^A-Za-z0-9 ]//;
		open (FILE, "<$dirError/$lang.error.conf") or die "cannot open file $dirError/$lang.error.conf";    
		while (<FILE>) {
			(my  $label, my  $value) = split(/=/);
			$SERVER{$label} = $value;	
		}
		close (FILE);
		}
}

sub loadMenu {
	my $string = "";
    $lang = $query->param("lang");
    loadLanguage();
	$string .=  "<li><a href=\"/cgi-bin/a.pl?lang=$lang&amp;page=art_design\" class=\"menulink\" >$SERVER{'art'}</a></li>";
	$string .=  "<li><a href=\"/cgi-bin/b.pl?lang=$lang&amp;page=parfum\" class=\"menulink\" >$SERVER{'parfum_cosmetik'}</a></li>";
	$string .=  "<li><a href=\"/cgi-bin/c.pl?lang=$lang&amp;page=wear_news\" class=\"menulink\" >$SERVER{'fashion'}</a></li>";
	$string .=  "<li><a href=\"/cgi-bin/d.pl?lang=$lang&amp;page=lingerie\" class=\"menulink\" >$SERVER{'lingerie'}</a></li>";
	$string .=  "<li><a href=\"/cgi-bin/e.pl?lang=$lang&amp;page=baby\" class=\"menulink\" >$SERVER{'baby'}</a></li>";
	$string .=  "<li><a href=\"/cgi-bin/f.pl?lang=$lang&amp;page=animal\" class=\"menulink\" >$SERVER{'animal'}</a></li>";
	$string .=  "<li><a href=\"/cgi-bin/g.pl?lang=$lang&amp;page=watch\" class=\"menulink\" >$SERVER{'watch_jewels'}</a></li>";
	$string .=  "<li><a href=\"/cgi-bin/h.pl?lang=$lang&amp;page=jardin\" class=\"menulink\" >$SERVER{'Habitat_et_jardin'}</a></li>";	
	$string .=  "<li><a href=\"/cgi-bin/i.pl?lang=$lang&amp;page=auto\" class=\"menulink\" >$SERVER{'car'}</a></li>";
	$string .=  "<li><a href=\"/cgi-bin/j.pl?lang=$lang&amp;page=moto\" class=\"menulink\" >$SERVER{'moto'}</a></li>";	
	$string .=  "<li><a href=\"/cgi-bin/immo.pl?lang=$lang&amp;page=immo\" class=\"menulink\" >$SERVER{'real_estate'}</a></li>";
	$string .=  "<li><a href=\"/cgi-bin/l.pl?lang=$lang&amp;page=cd_vinyl_mixtap\" class=\"menulink\" >$SERVER{'cd_music'}</a></li>";
	$string .=  "<li><a href=\"/cgi-bin/m.pl?lang=$lang&amp;page=intruments\" class=\"menulink\" >$SERVER{'music_instrument'}</a></li>";	
	$string .=  "<li><a href=\"/cgi-bin/n.pl?lang=$lang&amp;page=collection\" class=\"menulink\" >$SERVER{'collections'}</a></li>";
	$string .=  "<li><a href=\"/cgi-bin/o.pl?lang=$lang&amp;page=wine\" class=\"menulink\" >$SERVER{'wine'}</a></li>";
	$string .=  "<li><a href=\"/cgi-bin/p.pl?lang=$lang&amp;page=boat\" class=\"menulink\" >$SERVER{'boat'}</a></li>";		
	$string .=  "<li><a href=\"/cgi-bin/q.pl?lang=$lang&amp;page=tv_video\" class=\"menulink\" >$SERVER{'tv_video_camera'}</a></li>";	
	$string .=  "<li><a href=\"/cgi-bin/r.pl?lang=$lang&amp;page=games\" class=\"menulink\" >$SERVER{'games'}</a></li>";
	$string .=  "<li><a href=\"/cgi-bin/s.pl?lang=$lang&amp;page=book\" class=\"menulink\" >$SERVER{'book'}</a></li>";	
	$string .=  "<li><a href=\"/cgi-bin/t.pl?lang=$lang&amp;page=dvd\" class=\"menulink\" >$SERVER{'dvd_k7'}</a></li>";	
	$string .=  "<li><a href=\"/cgi-bin/u.pl?lang=$lang&amp;page=sport\" class=\"menulink\" >$SERVER{'sport'}</a></li>";
	return $string;

}


sub getWearSex {
    my $genre = $query->param("sex");
    $lang = $query->param("lang");
    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");
          
    my  $string .= "<select name=\"sex\" onchange=\"go5();\">";
    my  ($c)= $db->sqlSelectMany("libelle.libelle","categorie_libelle_langue, libelle, langue","categorie_libelle_langue.ref_categorie = 1 AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    if ($genre) {
	$string .= "<option selected value=\"$genre\">$genre</option>";
    }

    $string  .= "<option value=\"\">--------</option>";
    
    while( ($ARTICLE{'genre'})=$c->fetchrow()) {
	$string .= "<option value=\"/cgi-bin/c.pl?lang=$lang&amp;page=wear_news&amp;session=$session_id&amp;sex=$ARTICLE{'genre'}&amp;country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=with_lang_french&amp;with_lang_italian=$with_lang_italian&amp;with_lang_german=with_lang_german&amp;with_lang_english=$with_lang_english\">$ARTICLE{'genre'}</option>";
    }
    
    ($c)= $db->sqlSelectMany("libelle.libelle","categorie_libelle_langue, libelle, langue","categorie_libelle_langue.ref_categorie = 2 AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    
    while( ($ARTICLE{'genre'})=$c->fetchrow()) {
	$string .= "<option value=\"/cgi-bin/c.pl?lang=$lang&amp;page=wear_news&amp;type=6&session=$session_id&sex=$ARTICLE{'genre'}&country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=with_lang_french&with_lang_italian=$with_lang_italian&amp;with_lang_german=with_lang_german&with_lang_english=$with_lang_english\">$ARTICLE{'genre'}</option>";
    }

    $string .= "</select>";
    return $string;
	
}


sub getAnimalCategories {
    my $category = $query->param("category");
    my $subcat = $query->param("subcat");
    $lang = $query->param("lang");
    loadLanguage();
    
    my $u = $query->param("u");
    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");
          
    my  $string .= "<select name=\"category\" onchange=\"go();\">";
    my  ($c)= $db->sqlSelectMany("libelle.libelle","categorie_libelle_langue, libelle, langue","categorie_libelle_langue.ref_categorie = 33 AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    if ($category) {
	$string .= "<option selected value=\"$category\">$category</option>";
    }

    $string .= "<option>------</option>";
    
    while( ($ARTICLE{'genre'})=$c->fetchrow()) {
	$string .= "<option value=\"/cgi-bin/f.pl?lang=$lang&amp;page=animal&amp;session=$session_id&amp;category=$ARTICLE{'genre'}&subcat=$subcat&u=$u&amp;country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=with_lang_french&amp;with_lang_italian=$with_lang_italian&amp;with_lang_german=with_lang_german&amp;with_lang_english=$with_lang_english\">$ARTICLE{'genre'}</option>";
    }
    
    $string .= "</select>";
    return $string;
	
}


sub getWearType {
    $lang = $query->param("lang");  
    my $u = $query->param("u");
    my $genre = $query->param("sex");
    my $subcat = $query->param("subcat");
    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");
          
    my  $string .= "<select name=\"subcat\" onchange=\"go6();\">";
    my  ($c)= $db->sqlSelectMany("libelle.libelle","subcategorie_libelle_langue, libelle, langue","subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' AND subcategorie_libelle_langue.ref_categorie = (SELECT categorie_libelle_langue.ref_categorie FROM categorie_libelle_langue, libelle, langue WHERE libelle.libelle ='$genre' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang')");
    if ($subcat) {
	$string .= "<option selected value=\"$subcat\">$subcat</option>";
    }

    $string .= "<option>------</option>"; 
    while( ($ARTICLE{'genre'})=$c->fetchrow()) {
	$string .= "<option value=\"/cgi-bin/c.pl?lang=$lang&amp;page=wear_news&amp;type=6&u=$u&session=$session_id&sex=$genre&subcat=$ARTICLE{'genre'}&country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=with_lang_french&with_lang_italian=$with_lang_italian&amp;with_lang_german=with_lang_german&with_lang_english=$with_lang_english\">$ARTICLE{'genre'}</option>";
    }
    $string .= "</select>";
    return $string;
	
}

sub getSelectArticleDepot {
    my  ($c)= sqlSelectMany("ville","depot");
    my  $cat = $query->param("cat");
    $cat=~ s/[^A-Za-z0-9 ]//;
    my  $type = $query->param("type");
    $type =~ s/[^A-Za-z0-9 ]//;
    #my  $depot = $query->param("type");
    my  $string .= "<select name=\"navi\" onchange=\"go();\">";
    $string .= "<option>------</option>"; 
    while( ($ARTICLE{'genre'})=$c->fetchrow()) {
	$string .= "<option value=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&amp;cat=$cat&amp;type=$type&amp;depot=$ARTICLE{'genre'}\">$ARTICLE{'genre'}</option>";
    }
    $string .= "</select>";
    return $string;
    	
}


sub loadRegisterLongerPrice {
    my $string;
    my $account = $query->param("account_type");
    my $selected = $query->param("time");  
    my  ($c)= sqlSelect("prix","type_de_compte_libelle_langue, libelle, langue","libelle.libelle= '$account' AND type_de_compte_libelle_langue.ref_libelle = type_de_compte_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my $x = $c * $selected;
    $x =~ s/\[0-9]//g; ;
    my $s = "<tr><td>$SERVER{'tarif'} � </td><td><input type=\"text\" name=\"price\" value=\"$x\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"><td></tr>";
    return $s;
}

sub loadRegisterLongerTypeAccount {
    my  ($c)= sqlSelectMany("libelle.libelle","type_de_compte_libelle_langue, libelle, langue","type_de_compte_libelle_langue.ref_libelle = libelle.id_libelle AND type_de_compte_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my $s = "<td>$SERVER{'account_label'}</td><td><select name=\"account_type\" onchange=\"go();\">";
    my  %OPTIONS = ();
    my $selected = $query->param("account_type");
    $s .= "<option selected VALUE=\"$selected\">$selected</option>";
    while(($OPTIONS{'category'})=$c->fetchrow()) {	
         $s .= "<option value=\"/cgi-bin/recordz.cgi?lang=$lang&page=longer&session=$session_id&account_type=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";
	}
	$s .= "</select></td>";
    return $s;
}

sub loadRegisterTypeAccount {
    my $string;
    my  ($c)= $db->sqlSelectMany("libelle.libelle","type_de_compte_libelle_langue, libelle, langue","type_de_compte_libelle_langue.ref_libelle = libelle.id_libelle AND type_de_compte_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my $s = "";
    my  %OPTIONS = ();
    my $selected = $query->param("account_type");
    $s .= "<option selected VALUE=\"$selected\">$selected</option>";
    while(($OPTIONS{'category'})=$c->fetchrow()) {	
         $s .= "<option value=\"/cgi-bin/recordz.cgi?lang=$lang&page=register&session=$session_id&account_type=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";
    }
    return $s;
}

sub loadRegisterPrice {
    my $accountType = $query->param("account_type");
    my $accountDuration = $query->param("register_time");
    my $string;
    $string = "<tr><td>&nbsp;&nbsp;&nbsp;$SERVER{'register_price'}</td>";
    my  @c= $db->sqlSelect("prix","type_de_compte_libelle_langue, libelle, langue","type_de_compte_libelle_langue.ref_libelle = libelle.id_libelle AND type_de_compte_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' AND libelle.libelle = '$accountType'");
    my $price = $c[0];
    #print "Content-type: text/html\n\n";
    #print "price $price <br />";

    $price = $price * $accountDuration;
    $string .="<td><input type=\"text\" name=\"price\" value=\"$price\"</input></td>";
    return $string;
}

sub loadCategories {
    my $string;    
    my  %OPTIONS = ();
    $lang = $query->param("lang");
    my  ($c)= $db->sqlSelectMany("libelle.libelle","categorie_libelle_langue,libelle, langue","categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");	
    while(($OPTIONS{'category'})=$c->fetchrow()) {	
         $string .= "<option value=\"$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";
    }

    return $string;
}
sub loadRegisterTime {
    my $accountType = $query->param("account_type");
    my $registerTime = $query->param("register_time");
    my $lang = $query->param("lang");
    my $string;
    my  %OPTIONS = ();
    $string .="<tr>";
    $string .="<td align=\"left\"><label id=\"label_category_name\">&nbsp;&nbsp;&nbsp;$SERVER{'register_time'}</label></td>";			
    $string .= "<td align=\"left\"><select name=\"register_time\" onchange=\"go2();\">";
    $string .= "<option selected value=\"$registerTime\">$registerTime</option>";
    for (my $i = 1; $i < 13; $i++) {
	    $string .= "<option value=\"/cgi-bin/register.pl?lang=$lang&amp;page=register&session=$session_id&lang=$lang&register_time=$i&account_type=$accountType\">$i</option>";
    }
    $string .= "</select></td>";		
    return $string;    
    
    
}
sub loadRegisterCountry {
    my $string;
    my $accountType = $query->param("account_type");
    my  ($c)= $db->sqlSelectMany("nom","pays_present","id_pays_present = id_pays_present");	
    my $s = "";
    my  %OPTIONS = ();
    my $selected = $query->param("country_name");
    $s .= "<select name=\"register_time\" onchange=\"go();\">";
    $s .= "<option selected VALUE=\"$selected\">$selected</option>";
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {	
         $s .= "<option value=\"/cgi-bin/recordz.cgi?lang=$lang&page=register&session=$session_id&account_type=$accountType&country_name=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";
    }
    $s .="</select>";
    return $s;    
    
}

sub loadRegisterCountry2 {
    my $string;
    my $accountType = $query->param("account_type");
    my  ($c)= $db->sqlSelectMany("nom","pays_present","id_pays_present = id_pays_present");	
    my $s = "";
    my  %OPTIONS = ();
    my $selected = $query->param("country_name");

    $s .= "<option selected VALUE=\"$selected\">$selected</option>";
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {	
         $s .= "<option value=\"$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";
    }
    $s .="</select>";
    return $s;    
    
}

sub loadImmoCountry {
    my $string;
    my $u = $query->param("u");
    my $category = $query->param("category");
    my $subcategory = $query->param("subcategory");
    my $canton = $query->param("canton");
    my $location_type = $query->param("location_type");
    my $location_ou_achat = $query->param("location_ou_achat");
    my $country = $query->param("country_name"); 
    my  ($c)= $db->sqlSelectMany("nom","pays_present","id_pays_present = id_pays_present");	
    my  %OPTIONS = ();
    
    $string .= "<select name=\"country_name\" onchange=\"go();\">";
    $string .= "<option value=\"\">------</option>";
    if ($country) {
	$string .= "<option selected VALUE=\"$country\">$country</option>";
    }
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {	
         $string .= "<option value=\"/cgi-bin/immo.pl?lang=$lang&page=immo&session=$session_id&country_name=$OPTIONS{'category'}&category=$category&subcategory=$subcategory&location_ou_achat=$location_ou_achat&location_type=$location_type&canton=$canton\">$OPTIONS{'category'}</option>";
    }
    $string .="</select>";
    return $string;    

}

sub loadSearchImmoCountryToPopUp {
    my $string;
    my $u = $query->param("u");
    my $category = $query->param("category");
    my $subcategory = $query->param("subcategory");
    my $canton = $query->param("canton");
    my $location_type = $query->param("location_type");
    my $location_ou_achat = $query->param("location_ou_achat");
    my $country = $query->param("country_name"); 
    my  ($c)= $db->sqlSelectMany("nom","pays_present","id_pays_present = id_pays_present");	
    my  %OPTIONS = ();
    
    $string .= "<select name=\"country_name\" onchange=\"go6();\">";
    $string .= "<option value=\"\">------</option>";
    if ($country) {
	$string .= "<option selected VALUE=\"$country\">$country</option>";
    }
    
    while(($OPTIONS{'category'})=$c->fetchrow()) {	
         $string .= "<option value=\"/cgi-bin/immo.pl?lang=$lang&page=immo&session=$session_id&country_name=$OPTIONS{'category'}&category=$category&subcategory=$subcategory&location_ou_achat=$location_ou_achat&location_type=$location_type&canton=$canton&show_popup=true\">$OPTIONS{'category'}</option>";
    }
    $string .="</select>";
    return $string;    

}
    
sub loadSubCategoriesOther {
    my $maincat = $query->param("category");
    my $subcat = $query->param("subcat");
    my $load = $query->param("isencher");
    my $u = $query->param("u");
    my  ($c)= $db->sqlSelectMany("libelle.libelle",
			   "subcategorie_libelle_langue, libelle, langue",
			   "subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' AND subcategorie_libelle_langue.ref_categorie = (SELECT ref_categorie FROM categorie_libelle_langue, libelle, langue WHERE libelle.libelle = '$maincat' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')");
    my   $string = "";
    if ($c) {
		$string .="<tr>";
		$string .="<td align=\"left\"><label id=\"label_category_name\">$LABEL{'category'}</label></td>";			
     	        $string .= "<td align=\"left\"><select name=\"subcat\" onchange=\"go6();\">";
    if ($subcat) {
	$string .= "<option selected value=\"$subcat\">$subcat</option>";
    }
    $string .= "<option>------------</option>";
    my  %OPTIONS = ();
    while(($OPTIONS{'category'})=$c->fetchrow()) {
		 #my $entities = '&amp;';
		 #$OPTIONS{'category'} =~ s/[&]/$entities/ge;			      
	         $string .="<option value=\"/cgi-bin/add_other.pl?lang=$lang&amp;page=add_other&isencher=$load&session=$session_id&u=$u&category=$maincat&subcat=$OPTIONS{'category'};\">$OPTIONS{'category'}</option>";
	}
    $string .= "</select></td></tr>";
    }
    return $string;    
	
}
sub loadSubCategoriesOtherInformatic {
    my $maincat = $query->param("category");
    my $subcat = $query->param("subcat");
    my $load = $query->param("isencher");
    my $u = $query->param("u");
    my  ($c)= $db->sqlSelectMany("libelle.libelle",
			   "subcategorie_libelle_langue, libelle, langue",
			   "subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' AND subcategorie_libelle_langue.ref_categorie = (SELECT ref_categorie FROM categorie_libelle_langue, libelle, langue WHERE categorie_libelle_langue.ref_categorie = 7 AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')");
    my   $string = "";
    if ($c) {
		$string .="<tr>";
		$string .="<td align=\"left\"><label id=\"label_category_name\">$LABEL{'category'}</label></td>";			
     	        $string .= "<td align=\"left\"><select name=\"subcat\" onchange=\"go6();\">";
    if ($subcat) {
	$string .= "<option selected value=\"$subcat\">$subcat</option>";
    }
    $string .= "<option>------------</option>";
    my  %OPTIONS = ();
    while(($OPTIONS{'category'})=$c->fetchrow()) {
		 #my $entities = '&amp;';
		 #$OPTIONS{'category'} =~ s/[&]/$entities/ge;			      
	         $string .="<option value=\"/cgi-bin/add_other.pl?lang=$lang&amp;page=add_other&isencher=$load&session=$session_id&u=$u&category=$maincat&subcat=$OPTIONS{'category'};\">$OPTIONS{'category'}</option>";
	}
    $string .= "</select></td></tr>";
    }
    return $string;    
	
}

sub getCategoryGo {
    my $u = $query->param("u");
    my $load = $query->param("isencher");
    my  ($c)= $db->sqlSelectMany("libelle.libelle",
			   "categorie_libelle_langue, libelle, langue",
			   "categorie_libelle_langue.ref_categorie = categorie_libelle_langue.ref_categorie AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND  categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' ORDER BY id_libelle ");
    my $selected = $query->param("category");
    my  $string = "<option selected value=\"$selected\">$selected</option>";
    my  %OPTIONS = ();
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option VALUE=\"/cgi-bin/add_other.pl?lang=$lang&amp;page=add_other&isencher=$load&session=$session_id&category=$OPTIONS{'category'}&u=$u\">$OPTIONS{'category'}</option>" ;
	}
    return $string;    
}

sub loadEnchereProperties {
	my $u = $query->param("u");
	my $category = $query->param ("category");
	my $enchere_long = $query->param("enchere_long");        
        my $load = $query->param("isencher");
	my $subcat = $query->param("subcat");
        my $name =$query->param("name");
        my $fabricant= $query->param("fabricant");
        my $description = $query->param("description");
        my $price=  $query->param("price");
        my $selected = $enchere_long;
	my $wine_country = $query->param("wine_country");
	my $region = $query->param("region");
        my $wine_type = $query->param("wine_type");
	my $string;
	$ENV{TZ} = 'EST'; 
	my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
	my  $date = sprintf "%4d-%02d-%02d",$year+1900,$mon+1,$mday;	
	my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);	
	
	
	&Date_Init("Language=French","DateFormat=non-US","TZ=FST"); #French Summer Time 
        my  $date2 = ParseDateString("aujourd'hui");

	my   $currentDate = $date;
	my   $cutoffDate  = &DateCalc($date, "+ $enchere_long jours");
	
	my $year2 = substr($cutoffDate,0,4);
	my $month2 = substr($cutoffDate,4,2);
	my $day2 = substr($cutoffDate,6,2);
	my $cepage = $query->param("cepage");
	my $date_finish = "$year2-$month2-$day2";
	my $game_type = $query->param("game_type");
	
	$string .="<tr>";
		$string .="<td align=\"left\">$SERVER{'debut_enchere_label'}</td>";
		$string .="<td align=\"left\"><input type=\"text\" name=\"enchere_date_start\" value=\"$date $time\" style=\"width:120px\"></td>";		
	$string .="</tr>";
	$string .="<tr>";
		$string .="<td align=\"left\">$SERVER{'duree_enchere_label'}</td>";
		$string .="<td align=\"left\"><select name=\"duration_enchere\" onchange=\"go4();\">";
		$string .= "<option selected value=\"$selected\">$selected</option>";
		for (my $i = 1; $i < 31; $i++) {
			$string .= "<option value=\"/cgi-bin/add_other.pl?lang=$lang&amp;page=add_other&session=$session_id&u=$u&category=$category&subcat=$subcat&isencher=$load&enchere_long=$i&wine_country=$wine_country&region=$region&cepage=$cepage&wine_type=$wine_type&game_type=game_type\">$i</option>";
		}
		$string .= "</select></td>";		
	$string .="</tr>";
	$string .="<tr>";
		$string .="<td align=\"left\">$SERVER{'fin_enchere_label'}</td>";
		$string .="<td align=\"left\"><input type=\"text\" name=\"enchere_end_day\" value=\"$date_finish $time\" style=\"width:120px\"></td>";
	$string .="</tr>";
	
	return $string;
}

sub loadIsBuyOrLocation {
	my $string;
	$string .= "<tr>";
	$string .= "<td align=\"left\">$SERVER{'label_location_or_buy'}</td>";
	$string .= "<td align=\"left\"><select name=\"is_location_or_buy\">";
	$string .= "<option>$SERVER{'location'}</option>";
	$string .= "<option>$SERVER{'buy'}</option>";
	$string .= "</select></td>";
	$string .= "</tr>";
	return $string;
}

sub getIsEnchere {
    my $u = $query->param("u");
    my $category = $query->param ("category");
    my $wine_country = $query->param("wine_country");
    my $region = $query->param("region");
    my $load = $query->param("isencher");
    my $type_ecran = $query->param("type_ecran");
    my $subcat= $query->param ("subcat");
    my $cepage = $query->param("cepage");
    my $wine_type = $query->param("wine_type");
    my  $string ;
    $string .="<tr>";
    $string .="<td align=\"left\"><label id=\"label_image\">$SERVER{'avec_enchere'}</label></td>";
    $string .= "<td align=\"left\"><select name=\"is_enchere\" onchange=\"go3();\">";
    if ($load) {
	$string .= "<option selected value=\"$load\">$load</option>";
    }
    $string .= "<option>---------</option>";    
    $string .= "<option value=\"/cgi-bin/add_other.pl?lang=$lang&amp;page=add_other&session=$session_id&category=$category&isencher=$SERVER{'yes'}&u=$u&category=$category&subcat=$subcat&type_ecran=$type_ecran&wine_country=$wine_country&region=$region&cepage=$cepage&wine_type=$wine_type\">$SERVER{'yes'}</option>";
    $string .= "<option value=\"/cgi-bin/add_other.pl?lang=$lang&amp;page=add_other&session=$session_id&category=$category&isencher=$SERVER{'no'}&u=$u&category=$category&subcat=$subcat&type_ecran=$type_ecran&wine_country=$wine_country&region=$region&cepage=$cepage&wine_type=$wine_type\">$SERVER{'no'}</option>";    
    $string .= "</select>";
    $string .= "</td></tr>";
    return $string;    
}

sub loadTypeEcran {
    my $u = $query->param("u");
    my $category = $query->param ("category");
    my $subcat= $query->param ("subcat");
    my $load = $query->param("isencher");
    my $type_ecran = $query->param("type_ecran");
    my  ($c)= $db->sqlSelectMany("libelle.libelle",
			   "type_ecran_libelle_langue, libelle, langue",
			   "type_ecran_libelle_langue.ref_libelle = libelle.id_libelle AND type_ecran_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
  
    my  $string = "<tr>";
    $string .= "<td align=\"left\">$SERVER{'type_ecran'}</td>";
    $string .= "<td align=\"left\">";
    $string .= "<select name=\"type_ecran\" onchange=\"go5();\">";    
    $string .= "<option>---------</option>";
    if ($type_ecran) {
	$string .= "<option selected value=\"$type_ecran\">$type_ecran</option>";	
    }
    my  %OPTIONS = ();
    while(($OPTIONS{'category'})=$c->fetchrow()) {	
         $string .= "<option value=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=add_other&session=$session_id&category=$category&isencher=$load&subcat=$subcat&type_ecran=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";
	}
    $string .= "</select>";
    $string .= "</td>";
    $string .= "</tr>";
    return $string;    
	
}

sub loadFabricant {
    my $string;
    $string .= "<td align=\"left\">$SERVER{'fabricant'}</td>";
    $string .= "<td align=\"left\"><input type=\"text\" name=\"fabricant\" required></td>";
    $string .= "</tr>";
    return $string;	
}

sub getCarProperties {
    my $u = $query->param("u");
    my $maincat = $query->param("category");
    my $subcat = $query->param("subcat");
    my $load = $query->param("isencher");
    my $name =$query->param("name");;
    my $string;
    my $type_essence = $query->param("type_essence");
    my $speed_box = $query->param("speed_box");
    $string .="<tr><td align=\"left\">$SERVER{'chev'}</td><td align=\"left\"><input type=\"text\" name=\"horse\"></td></tr>";
    $string .="<tr><td align=\"left\">$SERVER{'nb_cylindre'}</td><td align=\"left\"><input type=\"text\" name=\"nb_cylindre\"></td></tr>";
    $string .="<tr><td align=\"left\">$SERVER{'nbr_km'}</td><td align=\"left\"><input type=\"text\" name=\"km\"></td></tr>";
    $string .="<tr><td align=\"left\">$SERVER{'year_fabrication'}</td><td align=\"left\"><input type=\"text\" name=\"year_fabrication\"></td></tr>";
    $string .="<tr><td align=\"left\">$SERVER{'year_service'}</td><td align=\"left\"><input type=\"text\" name=\"year_service\"></td></tr>";  
    $string .="<tr><td align=\"left\">$SERVER{'essence_type'}</td>";
    my  ($c)= $db->sqlSelectMany("libelle.libelle","type_essence_libelle_langue, libelle, langue","type_essence_libelle_langue.ref_libelle = libelle.id_libelle AND type_essence_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");	
    my  %OPTIONS = ();
    $string .="<td align=\"left\"><select name=\"type_essence\">";
    if ($type_essence) {$string .= "<option selected VALUE=\"$type_essence\">$type_essence</option>";}
    while(($OPTIONS{'category'})=$c->fetchrow()) {$string .= "<option>$OPTIONS{'category'}</option>";}
    $string .= "</select></td></tr><tr><td align=\"left\">$SERVER{'limp_speed'}</td>";
    
    my  ($d)= $db->sqlSelectMany("libelle.libelle","boite_de_vitesse_libelle_langue,libelle, langue","boite_de_vitesse_libelle_langue.ref_libelle = libelle.id_libelle AND boite_de_vitesse_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");	
    %OPTIONS = ();
    $string .="<td align=\"left\"><select name=\"speed_box\">";
    if ($speed_box) {$string .= "<option selected VALUE=\"$speed_box\">$speed_box</option>";}
    while(($OPTIONS{'category'})=$d->fetchrow()) {$string .= "<option>$OPTIONS{'category'}</option>";}
    $string .= "</select></td></tr><tr><td align=\"left\">$SERVER{'climatisation'}</td><td align=\"left\"><select name=\"with_clima\">";
    $string .= "<option>$SERVER{'yes'}</option><option>$SERVER{'no'}</option></select></td>";
    $string .= "</tr>";
    return $string;

}

sub loadDimension {
	
}



sub loadCityLocation {
	my $string;
	my $category = $query->param("category");
	my $subcat = $query->param("subcat");
	my $country = $query->param("country");
	my $departement = $query->param("departement");
	my $canton = $query->param ("canton");
	my $dep;
	my $label;
	my $c = loadAddImmoCountry();;
	$string .= "<tr>";
	$string .= "<td align=\"left\">$SERVER{'country'}</td>";
	$string .= "<td align=\"left\">$c</td>";
	
	$string .= "</tr>";
	if ($country eq 'Suisse') {
		$label = "$SERVER{'canton'}";
		$dep = loadAddImmoCanton2();
	}elsif ($country eq 'France') {
		$label = "$SERVER{'depatement'}";
		$dep = loadAddImmoDepartement();
	}

	$string .= "<tr>";
	$string .= "<td align=\"left\">$label</td>";
	$string .= "<td align=\"left\">$dep</td>";
	$string .= "</tr>";
	$string .= "<td align=\"left\">$SERVER{'city_label'}</td>";$string .= "<td align=\"left\"><input type=\"text\" name=\"city\"></td>";
	$string .= "</tr>";
	$string .= "<tr><td align=\"left\">$SERVER{'adress_label'}</td><td align=\"left\"><input type=\"text\" name=\"adress\"></td></tr>";
	$string .= "<tr><td align=\"left\">$SERVER{'nbr_piece'}</td><td align=\"left\"><input type=\"text\" name=\"nbr_piece\"></td></tr>";
	$string .= "<tr><td align=\"left\">$SERVER{'habitable_surface'}</td><td align=\"left\"><input type=\"text\" name=\"habitable_surface\"></td></tr>";
	$string .= "<tr><td align=\"left\">$SERVER{'terrain_surface'}</td><td align=\"left\"><input type=\"text\" name=\"terrain_surface\"></td></tr>";
	$string .= "<tr><td align=\"left\">$SERVER{'date_construction'}</td><td align=\"left\"><input type=\"text\" name=\"date_construction\"></td></tr>";
	$string .= "<tr><td align=\"left\">$SERVER{'code_postal'}</td><td align=\"left\"><input type=\"text\" name=\"code_postal\"></td></tr>";
	return $string;
}
sub timeDiff {
	my $invoke = shift || '';
	my $date1 = shift || '';
	my $date2 = shift || '';
#'2005-08-02 0:26:47', date2 =>  '2005-08-03 13:27:46'
	my  @offset_days = qw(0 31 59 90 120 151 181 212 243 273 304 334);

	my $year1  = substr($date1, 0, 4);
	my $month1 = substr($date1, 5, 2);
	my $day1   = substr($date1, 8, 2);
	my $hh1    = substr($date1,11, 2) || 0;
	my $mm1    = substr($date1,14, 2) || 0;
	my $ss1    = 0;
	$ss1 = substr($date1,17, 2) if (length($date1) > 16);
		 #$ss1  ||= 0;

	my $year2  = substr($date2, 0, 4);
	my $month2 = substr($date2, 5, 2);
	my $day2   = substr($date2, 8, 2);
	my $hh2    = substr($date2,11, 2) || 0;
	my $mm2    = substr($date2,14, 2) || 0;
	my $ss2    = 0;
	$ss2 = substr($date2,17, 2) if (length($date2) > 16);
	   #$ss2  ||= 0;

	my $total_days1 = $offset_days[$month1 - 1] + $day1 + 365 * $year1;
	my $total_days2 = $offset_days[$month2 - 1] + $day2 + 365 * $year2;
	my $days_diff   = $total_days2 - $total_days1;

	my $seconds1 = $total_days1 * 86400 + $hh1 * 3600 + $mm1 * 60 + $ss1;
	my $seconds2 = $total_days2 * 86400 + $hh2 * 3600 + $mm2 * 60 + $ss2;

	my $ssDiff = $seconds2 - $seconds1;

	my $dd     = int($ssDiff / 86400);
	my $hh     = int($ssDiff /  3600) - $dd *    24;
	my $mm     = int($ssDiff /    60) - $dd *  1440 - $hh *   60;
	my $ss     = int($ssDiff /     1) - $dd * 86400 - $hh * 3600 - $mm * 60;

	return "$dd J $hh H $mm M $ss Sec";
}


sub loadTvDimension {
    $lang = $query->param("lang");
    loadLanguage();

	my $u = $query->param("u");
	my $string;$string .= "<tr>";$string .= "<td align=\"left\">$SERVER{'dimension'}</td>";$string .= "<td align=\"left\"><input type=\"text\" name=\"dimension\"></td>";$string .= "</tr>";
	return $string;
}

sub loadInfoPcProperties {
	my $string;
    $lang = $query->param("lang");
    loadLanguage();
	$string .= "<tr>";$string .= "<td align=\"left\">$SERVER{'processor_ghz'}</td><td align=\"left\"><input name=\"processor\" type=\"number\"></td>";$string .= "</tr>";
	$string .= "<tr>";$string .= "<td align=\"left\">$SERVER{'hard_drive_capacity'}</td><td align=\"left\"><input  name=\"hard_drive\" type=\"number\"></td>";
	$string .= "</tr>";$string .= "<tr>";$string .= "<td align=\"left\">$SERVER{'ram'}</td><td align=\"left\"><input  name=\"ram\" type=\"number\"></td>";$string .= "</tr>";
	return $string;
	
}

sub loadInfoCarteMereProperties {
	my $string;
    $lang = $query->param("lang");
    loadLanguage();
	$string .= "<tr>";$string .= "<td align=\"left\">$SERVER{'processor_ghz'}</td><td align=\"left\"><input  name=\"processor\" type=\"number\"></td>";$string .= "</tr>";
	$string .= "</tr>";$string .= "<tr>";$string .= "<td align=\"left\">$SERVER{'ram'}</td><td align=\"left\"><input  name=\"ram\" type=\"number\"></td>";$string .= "</tr>";
	return $string;
	
}sub loadInfoLogicielProperties {
	my $string;
    $lang = $query->param("lang");
    loadLanguage();    
	$string .= "<tr>";$string .= "<td align=\"left\">$SERVER{'editeur'}</td><td align=\"left\"><input type=\"text\" name=\"processor\"></td>";$string .= "</tr>";
	$string .= "<tr>";$string .= "<td align=\"left\">$SERVER{'nom_logiciel'}</td><td align=\"left\"><input type=\"text\" name=\"hard_drive\"></td></tr>";	
	return $string;
	
}

sub loadQuantity {
	my $string;
	my $invoke = shift || '';
	my $quantity = shift || '';
    $lang = $query->param("lang");
    loadLanguage();
    
	$string .= "<tr>";$string .= "<td align=\"left\">$SERVER{'article_quantity_label'}</td><td align=\"left\"><input type=\"text\" name=\"quantity\" value=\"$quantity\"</input></td>";
	$string .= "</tr>";
	return $string;
}

sub loadAddWineCountry {
	my $u = $query->param("u");
	my $string;
	my $category = $query->param ("category");
	my $subcat= $query->param ("subcat");
        my $load = $query->param("isencher");
	my $selected = $query->param("wine_country");
	my $wine_type = $query->param("wine_type");
	my $region = $query->param("region");
	my $cepage = $query->param("cepage");
	$string .= "<tr>";$string .= "<td align=\"left\">$SERVER{'wine_country'}</td>";
	$string .= "<td align=\"left\"><select name=\"wine_country\" onchange=\"go11();\">";
	    my  ($c)= $db->sqlSelectMany("nom",
			   "pays_region_vin",
			   "id_pays_region_vin = id_pays_region_vin");

        my  %OPTIONS = ();
	$string .= "<option>---------</option>";
	if ($selected) {$string  .= "<option selected value=\"$selected\">$selected</option>";}
	while(($OPTIONS{'category'})=$c->fetchrow()) {
	    $string .= "<option value=\"/cgi-bin/add_other.pl?lang=$lang&amp;page=add_other&session=$session_id&u=$u&category=$category&region=$selected&isencher=$load&subcat=$subcat&wine_country=$OPTIONS{'category'}&cepage=$cepage&wine_type=$wine_type\">$OPTIONS{'category'}</option>";
	}
	$string .= "</select></td>";
	$string .= "</tr>";	
}

sub loadWineYear {
    my $string;
    $string .= "<tr><td>$SERVER{'year'}</td><td><input type=\"text\" name=\"year_fabrication\"></input></td></tr>";
    return $string;
}

sub loadAddImmoCountry {
    my $category = $query->param("category");
    my $subcat = $query->param("subcat");
    my $duration_enchere = $query->param("enchere_long");
    my $u = $query->param("u");
    my $isencher = $query->param("isencher");
    my  ($c)= $db->sqlSelectMany("nom","pays_present", "id_pays_present = id_pays_present");
    my $selected = $query->param("country");
    my $string = "<select name=\"country\" onchange=\"go9();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("departement");
    if ($selected) {$string  .= "<option selected value=\"$selected\">$selected</option>";}
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();   
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	$string .= "<option VALUE=\"/cgi-bin/add_other.pl?lang=$lang&amp;page=add_other&session=$session_id&country=$OPTIONS{'category'}&category=$category&subcat=$subcat&isencher=$isencher&u=$u&enchere_long=$duration_enchere\">$OPTIONS{'category'}</option>";
    }
    $string .= "</select>";
    return $string;    
	
}
 
sub loadAddImmoCanton {
    my $u = $query->param("u");
    my $category = $query->param("category");
    my $canton = $query->param("dep");my $country = $query->param("country");
    my $subcat = $query->param("subcat");my $immo_type = $query->param("immo_type");
    my $dep = $query->param("dep");
    my $location_type = $query->param("location_type");
    my $departement = $query->param("departement");
    my  ($c)= $db->sqlSelectMany("nom", "canton_fr",  "id_canton = id_canton");    
    my $string = "<select name=\"dep\" onchange=\"go2();	\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    if ($canton) {$string  .= "<option selected value=\"$canton\">$canton</option>";
	$string  .= "<option value=\"\">--------</option>";
	my  %OPTIONS = ();
	while(($OPTIONS{'category'})=$c->fetchrow()) {
	    $string .= "<option value=/cgi-bin/recordz.cgi?lang=$lang&amp;page=immo&category=$category&session=$session_id&u=$u&dep=$OPTIONS{'category'}&location_type=$location_type\">$OPTIONS{'category'}</option>\n";
	}
	$string .= "</select>";
	return $string;    
	    
    }
}

sub loadAddImmoCanton2 {
    my $departement = $query->param("departement");my $canton = $query->param("canton");
    my $u = $query->param("u");
    my $category = $query->param("category");my $subcat = $query->param("subcat");
    my $country = $query->param("country");my $immo_type = $query->param("immo_type");
    my $location_type = $query->param("location_type");
    $lang = lc($lang);
    my  ($c)= $db->sqlSelectMany("nom","canton_$lang","id_canton = id_canton");    
    my $string = "<select name=\"departement\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    if ($departement) {$string  .= "<option selected value=\"$departement\">$departement</option>";}
    $string .= "<option value=\"\">------</option>"; 
    my  %OPTIONS = ();
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	#$string .= "<option VALUE=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=add_other&session=$session_id&departement=$OPTIONS{'category'}&country=$country&canton=$canton&immo_type=$immo_type&location_type=$location_type&category=$category&subcat=$subcat&departement=$OPTIONS{'category'}\">$OPTIONS{'category'}($OPTIONS{'code'})</option>" ;
	$string .=  "<option value=\"$OPTIONS{'category'}\">$OPTIONS{'category'}</option>\n";
	}
    $string .= "</select>";
    return $string;    
	
	
}

sub loadAddImmoDepartement {
    my $category = $query->param("category");
    my $departement = $query->param("departement");
    my $subcategory = $query->param("subcategory");
    my $canton = $query->param("canton");
    my $location_type = $query->param("location_type");
    my $location_ou_achat = $query->param("location_ou_achat");
																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																							
    my  ($c)= $db->sqlSelectMany("nom,code","departement","id_departement = id_departement");    
    my $string = "<select name=\"departement\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    if ($departement) {$string  .= "<option selected value=\"$departement\">$departement</option>";}
    my  %OPTIONS = ();
    while(($OPTIONS{'category'},$OPTIONS{'code'})=$c->fetchrow()) {
	#$string .= "<option VALUE=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=add_other&session=$session_id&departement=$OPTIONS{'category'}&country=$country&canton=$canton&immo_type=$immo_type&location_type=$location_type&category=$category&subcat=$subcat&departement=$OPTIONS{'category'}\">$OPTIONS{'category'}($OPTIONS{'code'})</option>" ;
	$string .=  "<option value='/cgi-bin/immo.pl?lang=$lang&amp;page=immo&category=$category&session=$session_id&departement=$OPTIONS{'category'}&location_type=$location_type&location_ou_achat=$location_ou_achat'\">$OPTIONS{'category'}($OPTIONS{'code'})</option>\n";
	}
    $string .= "</select>";
    return $string;    
	
}

sub loadAddImmoDepartementToSearch {
    my $category = $query->param("category");
    my $departement = $query->param("departement");
    my $subcategory = $query->param("subcategory");
    my $canton = $query->param("canton");
    my $location_type = $query->param("location_type");
    my $location_ou_achat = $query->param("location_ou_achat");
																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																							
    my  ($c)= $db->sqlSelectMany("nom,code","departement","id_departement = id_departement");    
    my $string = "<select name=\"departement\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    if ($departement) {$string  .= "<option selected value=\"$departement\">$departement</option>";}
    my  %OPTIONS = ();
    while(($OPTIONS{'category'},$OPTIONS{'code'})=$c->fetchrow()) {
	#$string .= "<option VALUE=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=add_other&session=$session_id&departement=$OPTIONS{'category'}&country=$country&canton=$canton&immo_type=$immo_type&location_type=$location_type&category=$category&subcat=$subcat&departement=$OPTIONS{'category'}\">$OPTIONS{'category'}($OPTIONS{'code'})</option>" ;
	$string .=  "<option value='/$OPTIONS{'category'}'\">$OPTIONS{'category'}($OPTIONS{'code'})</option>\n";
	}
    $string .= "</select>";
    return $string;    
	
}

sub loadAddImmoDepartementTosearch {
    my $category = $query->param("category");
    my $departement = $query->param("departement");
    my $subcategory = $query->param("subcategory");
    my $canton = $query->param("canton");
    my $location_type = $query->param("location_type");
    my $location_ou_achat = $query->param("location_ou_achat");
																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																							
    my  ($c)= $db->sqlSelectMany("nom,code","departement","id_departement = id_departement");    
    my $string = "<select name=\"departement\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    if ($departement) {$string  .= "<option selected value=\"$departement\">$departement</option>";}
    my  %OPTIONS = ();
    while(($OPTIONS{'category'},$OPTIONS{'code'})=$c->fetchrow()) {
	#$string .= "<option VALUE=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=add_other&session=$session_id&departement=$OPTIONS{'category'}&country=$country&canton=$canton&immo_type=$immo_type&location_type=$location_type&category=$category&subcat=$subcat&departement=$OPTIONS{'category'}\">$OPTIONS{'category'}($OPTIONS{'code'})</option>" ;
	$string .=  "<option value='\$OPTIONS{'category'}'\">$OPTIONS{'category'}($OPTIONS{'code'})</option>\n";
	}
    $string .= "</select>";
    return $string;    
    
}
sub loadAddImmoDepartement2 {
    my $category = $query->param("category");
    my $subcategory = $query->param("subcategory");
    my $canton = $query->param("canton");
    my $location_type = $query->param("location_type");
    my $location_ou_achat = $query->param("location_ou_achat");
    my $country = $query->param("country_name");
    $lang = lc($lang);
    my  ($c)= $db->sqlSelectMany("nom","canton_$lang","id_canton = id_canton");    
    my $string = "<select name=\"canton\" onchange=\"go5();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    if ($canton) {$string  .= "<option selected value=\"$canton\">$canton</option>";}
    $string .= "<option value=\"\">------</option>"; 
    my  %OPTIONS = ();
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	#$string .= "<option VALUE=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=add_other&session=$session_id&departement=$OPTIONS{'category'}&country=$country&canton=$canton&immo_type=$immo_type&location_type=$location_type&category=$category&subcat=$subcat&departement=$OPTIONS{'category'}\">$OPTIONS{'category'}($OPTIONS{'code'})</option>" ;
	$string .=  "<option value='/cgi-bin/immo.pl?lang=$lang&amp;page=immo&category=$category&subcategory=$subcategory&country_name=$country&session=$session_id&canton=$OPTIONS{'category'}&location_type=$location_type&location_ou_achat=$location_ou_achat'\">$OPTIONS{'category'}</option>\n";
	}
    $string .= "</select>";
    return $string;    
	
}

sub loadAddImmoDepartement2ToSearch {
    my $category = $query->param("category");
    my $subcategory = $query->param("subcategory");
    my $canton = $query->param("canton");
    my $location_type = $query->param("location_type");
    my $location_ou_achat = $query->param("location_ou_achat");
    my $country = $query->param("country_name");
    $lang = lc($lang);
    my  ($c)= $db->sqlSelectMany("nom","canton_$lang","id_canton = id_canton");    
    my $string = "<select name=\"canton\"  onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    if ($canton) {$string  .= "<option selected value=\"$canton\">$canton</option>";}
    $string .= "<option value=\"\">------</option>"; 
    my  %OPTIONS = ();
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	#$string .= "<option VALUE=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=add_other&session=$session_id&departement=$OPTIONS{'category'}&country=$country&canton=$canton&immo_type=$immo_type&location_type=$location_type&category=$category&subcat=$subcat&departement=$OPTIONS{'category'}\">$OPTIONS{'category'}($OPTIONS{'code'})</option>" ;
	$string .=  "<option value='$OPTIONS{'category'}'\">$OPTIONS{'category'}</option>\n";
	}
    $string .= "</select>";
    return $string;    
	
}

sub loadOffshoreProperties {
	my $string;
	$string .= "<tr>";$string .= "<td>$SERVER{'longueur'}</td><td><input type=\"text\" name=\"longueur\"></td>";
	$string .= "<td>$SERVER{'largeur'}</td><td><input type=\"text\" name=\"largeur\"></td>";
	$string .= "</tr>";$string .= "<tr>";$string .= "<td>$SERVER{'chev'}</td><td><input type=\"text\" name=\"horse\"></td>";
	$string .= "</tr>";$string .= "<tr>";$string .= "<td>$SERVER{'conso'}</td><td><input type=\"text\" name=\"conso\"></td>";$string .= "</tr>";
	return $string;
}


sub loadAddGamesType {
    my $u = $query->param("u");
    my $category = $query->param("category");my $subcat = $query->param("subcat");
    my $enchere_long = $query->param("enchere_long"); my $load = $query->param("isencher");
    my $cepage = $query->param("cepage");
    my  ($c)= $db->sqlSelectMany("libelle.libelle","type_de_jeux_libelle_langue, libelle, langue","type_de_jeux_libelle_langue.ref_libelle = libelle.id_libelle AND type_de_jeux_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my $selected = $query->param("game_type");
    my $string	;
    $string .= "<tr>";$string .= "<td>$SERVER{'game_type'}</td>";
    $string .= "<td><select name=\"game_type\" onchange=\"go10();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">"; 
    if ($selected) {$string  .= "<option selected value=\"$selected\">$selected</option>";  }
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();
    while(($OPTIONS{'category'})=$c->fetchrow()) {$string .= "<option VALUE=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=add_other&session=$session_id&u=$u&category=$category&subcat=$subcat&game_type=$OPTIONS{'category'}&isencher=$load&enchere_long=$enchere_long&cepage=$cepage\">$OPTIONS{'category'}</option>";	}
    $string .= "</select></td>";
    $string .= "</tr>";
    return $string;    
	
}
sub loadAddWineRegion {
    my $u = $query->param("u");
    my $country = $query->param("wine_country");my $region = $query->param("region");my $category = $query->param ("category");
    my $subcat= $query->param ("subcat");my $load = $query->param("isencher");my $cepage = $query->param("cepage");
    my $wine_type = $query->param("wine_type");
    my  ($c)= $db->sqlSelectMany("pays_region_vin.nom","pays_region_vin,pays_present","ref_pays = id_pays_present AND pays_present.nom = '$country' AND  parent_id IS NOT NULL ORDER BY pays_region_vin.nom");    
    my $string = "<td align=\"left\">$SERVER{'region_label'}</td><td align=\"left\"><select name=\"region\" onchange=\"go12();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("departement");
    if ($region) {$string  .= "<option selected value=\"$region\">$region</option>";}
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();    
    while(($OPTIONS{'category'})=$c->fetchrow()) {$string .= "<option VALUE=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=add_other&session=$session_id&u=$u&wine_country=$country&region=$OPTIONS{'category'}&category=$category&subcat=$subcat&isencher=$load&cepage=$cepage&wine_type=$wine_type\">$OPTIONS{'category'}</option>" ;}
    $string .= "</select></td>";
    return $string;    
	
}


sub loadAddWineCepage {
    my $u = $query->param("u");
    my $country = $query->param("wine_country");
    my $region = $query->param("region");
    my $cepage = $query->param("cepage");
    my $category = $query->param ("category");
    my $subcat= $query->param ("subcat");
    my $load = $query->param("isencher");
    my $wine_type = $query->param("wine_type");
    my  ($c)= $db->sqlSelectMany("cepage.nom","pays_region_vin,cepage","cepage.ref_pays_region_vin = pays_region_vin.id_pays_region_vin AND pays_region_vin.nom = '$region'");    
    my $string = "<tr>";
    $string .= "<td align=\"left\">$SERVER{'cepage'}</td><td align=\"left\"><input type=\"text\" name=\"cepage\"  onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\"></input>";
    return $string;    
	
	
}


sub loadWineCepage {
    $lang = $query->param("lang");
    my $country = $query->param("country");
    my $cepage = $query->param("cepage");
    my $wine_type = $query->param("wine_type");
    my @type_de_vin = $db->sqlSelect("ref_type_de_vin", "type_de_vin_libelle_langue, libelle, langue", "libelle.libelle = '$wine_type' AND type_de_vin_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' and type_de_vin_libelle_langue.ref_libelle = libelle.id_libelle");
    my $ref_type_de_vin = $type_de_vin[0];
    my $string .= "<select name=\"cepage\" onchange=\"go3();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    if ($ref_type_de_vin) {
	my  ($c)= $db->sqlSelectMany("cepage.nom","pays_region_vin,cepage","cepage.ref_pays_region_vin = pays_region_vin.id_pays_region_vin AND pays_region_vin.nom = '$country'  and cepage.ref_type_de_vin = $ref_type_de_vin");    
	if ($cepage) {
	    $string  .= "<option selected value=\"$cepage\">$cepage</option>";}
	    $string  .= "<option value=\"\">--------</option>";
	    my  %OPTIONS = ();    
	    while(($OPTIONS{'category'})=$c->fetchrow()) {$string .= "<option VALUE=\"/cgi-bin/o.pl?lang=$lang&amp;page=wine&session=$session_id&country=$country&cepage=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>" ;}
    }
    $string .= "</select>";
    return $string;    
	
	
}

sub loadAddWineType {
    $lang = $query->param("lang");
    my $u = $query->param("u");
    my $country = $query->param("wine_country");my $region = $query->param("region");my $cepage = $query->param("cepage");
    my $category = $query->param ("category");my $subcat= $query->param ("subcat");my $load = $query->param("isencher");
    my ($c)= $db->sqlSelectMany("libelle.libelle","type_de_vin_libelle_langue, libelle, langue","type_de_vin_libelle_langue.ref_libelle = libelle.id_libelle AND type_de_vin_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my $selected = $query->param("wine_type");   
    my $string = "<tr><td>$SERVER{'wine_type'}</td><td><select name=\"wine_type\" onchange=\"go14();\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    my $departement = $query->param("departement");
    if ($selected) {$string  .= "<option selected value=\"$selected\">$selected</option>";}
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();    
    while(($OPTIONS{'category'})=$c->fetchrow()) {$string .= "<option VALUE=\"/cgi-bin/add_other.pl?lang=$lang&amp;page=add_other&session=$session_id&u=$u&wine_country=$country&wine_type=$OPTIONS{'category'}&region=$region&isencher=$load&category=$category&subcat=$subcat&cepage=$cepage\">$OPTIONS{'category'}</option>" ;}
    $string .= "</select></td></tr>";
    return $string;    
}

sub loadSearchJardinFabricants {
    my $category = $query->param('category');
    my $subcategory = $query->param('subcategory');
    my $selected = $query->param('fabricant');
    my $country = $query->param("country");
    my $subcat = $query->param("subcat");
    my $string;
    my ($c)= sqlSelectMany("DISTINCT article.marque","article, categorie_libelle_langue, subcategorie_libelle_langue","article._refsubcategorie = subcategorie_libelle_langue.ref_subcategorie AND article.ref_categorie = categorie_libelle_langue.ref_categorie AND subcategorie_libelle_langue.ref_subcategorie = (SELECT ref_subcategorie FROM subcategorie_libelle_langue, libelle, langue WHERE libelle.libelle = '$subcategory' AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang') AND article.ref_categorie = (SELECT ref_categorie FROM categorie_libelle_langue, libelle, langue WHERE categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key =  '$lang");
    $string .= "<tr>";
    $string = "<td>$SERVER{'fabricant'}</td><td><select name=\"fabricant\" onchange=\"go3);\" onfocus=\"skipcycle=true\" onblur=\"skipcycle=false\">";
    if ($selected) {$string  .= "<option selected value=\"$selected\">$selected</option>";} 
    $string  .= "<option value=\"\">--------</option>";
    my  %OPTIONS = ();    
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	$string .= "<option VALUE=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=search_jardin&session=$session_id&wine_country=$country&fabricant=$OPTIONS{'category'}&category=$category&subcat=$subcat\">$OPTIONS{'category'}</option>" ;
    }
    $string .= "</select></td></tr>";
    return $string;
}
sub loadAutor {
	my $string;
	$string .= "<tr><td>$SERVER{'autor'}</td><td><input type=\"text\" name=\"autor\" onchange=\"validateInput()\"></td>";
	$string .= "<tr><td>$SERVER{'year'}</td><td><input type=\"text\" name=\"year\" onchange=\"validateYear()\"></td>";
	return $string;
}


sub loadUsedOrNew {
    my $country = $query->param("wine_country");my $region = $query->param("region");my $cepage = $query->param("cepage");
    my $category = $query->param ("category");my $subcat= $query->param ("subcat");my $load = $query->param("isencher");
    my $string;my  ($c)= $db->sqlSelectMany("libelle.libelle", "etat_libelle_langue, libelle, langue", "etat_libelle_langue.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my  %OPTIONS = ();
    $string .= "<td align=\"left\">$SERVER{'used'}</td><td align=\"left\"><select name=\"used\">";
    while(($OPTIONS{'category'})=$c->fetchrow()) {$string .= "<option>$OPTIONS{'category'}</option>";}
    $string .= "</select></td></tr>";
    return $string;    
	
}
sub getCategoryID {
    my  $category = shift || '';
    my  ($c)= $db->sqlSelectMany("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");	
    my  $string = "";my  %OPTIONS = ();
    while(($OPTIONS{'category'})=$c->fetchrow()) {$string .= "$OPTIONS{'category'}";}
    return $string;    
}

sub getCurrentCarProperties {
    loadLanguage();
    my $maincat = $query->param("category");
    my $subcat = $query->param("subcat");
    my $load = $query->param("isencher");
    my $name =$query->param("name");
    my $article = $query->param("article");
    my $string;
    my $clima;



  ($ARTICLE{'nb_cheveaux'},
   $ARTICLE{'nb_km'},
   $ARTICLE{' premiere_immatriculation '},
   $ARTICLE{'annee_construction'},
   $ARTICLE{'ref_type_essence'},
   $ARTICLE{'ref_boite_de_vitesse'}, 
   $ARTICLE{'clima'})= $db->sqlSelect("nb_cheveaux,nb_km,premiere_immatriculation , annee, ref_type_essence, article.ref_boite_de_vitesse, clima","article,boite_de_vitesse_libelle_langue,type_essence_libelle_langue","id_article ='$article'");	
  #print "Content-Type: text/html\n\n";
    #print "boite de vitesse  $ARTICLE{'ref_boite_de_vitesse'}";

    my ($type_essence) = $db->sqlSelect("libelle.libelle", "type_essence_libelle_langue, libelle, langue",
					"type_essence_libelle_langue.ref_type_essence = '$ARTICLE{'ref_type_essence'}' AND type_essence_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' and type_essence_libelle_langue.ref_libelle = libelle.id_libelle");
    my ($ref_boite_de_vitesse) = $db->sqlSelect("libelle.libelle", "boite_de_vitesse_libelle_langue, libelle, langue",
						"boite_de_vitesse_libelle_langue.ref_boite_de_vitesse = '$ARTICLE{'ref_boite_de_vitesse'}' AND boite_de_vitesse_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' and boite_de_vitesse_libelle_langue.ref_libelle = libelle.id_libelle");
    if ($ARTICLE{'clima'} eq '0') {$clima = $SERVER{'no'};}else {$clima = $SERVER{'yes'};}
    $string .="<tr>";$string .="<td align=\"left\" width=\"120\">$SERVER{'chev'}</td>";
    $string .="<td align=\"left\" width=\"120\"><input type=\"text\" name=\"horse\" value=\"$ARTICLE{'nb_cheveaux'}\"></td>";
    $string .="</tr>";$string .="<tr>";$string .="<td align=\"left\" width=\"120\">$SERVER{'nbr_km'}</td>";
    $string .="<td align=\"left\" width=\"120\"><input type=\"text\" name=\"km\" value=\"$ARTICLE{'nb_km'}\"></td>";
    $string .="</tr>";$string .="<tr>";$string .="<td align=\"left\" width=\"120\">$SERVER{'year_fabrication'}</td>";
    $string .="<td align=\"left\" width=\"120\"><input type=\"text\" name=\"year_fabrication\" value=\"$ARTICLE{'annee_construction'}\"></td>";
    $string .="</tr>";$string .="<tr>";$string .="<td align=\"left\" width=\"120\">$SERVER{'year_service'}</td>";
    $string .="<td align=\"left\" width=\"120\"><input type=\"text\" name=\"year_service\" value=\"$ARTICLE{' premiere_immatriculation '}\"></td>";
    $string .="</tr>";$string .="<tr>";$string .="<td align=\"left\" width=\"120\">$SERVER{'essence_type'}</td>";
    $string .="<td align=\"left\" width=\"120\"><input type=\"text\" value=\"$type_essence\">";
    $string .= "</td>";$string .="<tr>";$string .="<td align=\"left\" width=\"120\">$SERVER{'limp_speed'}</td>";
    $string .="<td align=\"left\" width=\"120\"><input type=\"text\" value=\"$ref_boite_de_vitesse\">";
    $string .= "</td>";$string .="<tr>"; $string .="<td align=\"left\" width=\"120\">$SERVER{'climatisation'}</td>";
    $string .="<td align=\"left\">$clima</td>";
    $string .= "</tr>";
    return $string;
}

sub loadDimensionOther {
	my $string;my $dimension = shift || '';
	$string .= "<tr><td align=\"left\">Dimension: </td><td align=\"left\"><input type=\"text\" name=\"dimension\" value=\"$dimension\"></td></tr>";
	return $string;
}


sub loadDetailInfoPcProperties {
    loadLanguage();
    my $string;
    my $call = shift || '';
    my $processor = shift || '';
    my $hard_drive2 = shift || '';
    my $ram = shift || '';
    $string .= "<tr><td align=\"left\">$SERVER{'processor_ghz'}</td><td align=\"left\"><input type=\"text\" name=\"processor\" value=\"$processor\"></td></tr>";
    $string .= "<tr><td align=\"left\">$SERVER{'hard_drive_capacity'}</td><td align=\"left\"><input type=\"text\" name=\"hard_drive\" value=\"$hard_drive2\"></td></tr>";
    $string .= "<tr><td align=\"left\">$SERVER{'ram'}</td><td align=\"left\"><input type=\"text\" name=\"ram\" value=\"$ram\"></td></tr>";
    return $string;
}

sub loadPayementModeProperties {
	my $string;
	my $article = $query->param("article");
        my @deliver = $db->sqlSelect("libelle.libelle ", "condition_livraison_libelle_langue,article,libelle, langue", "article.ref_condition_livraison = condition_livraison_libelle_langue.ref_condition_livraison and id_article ='$article' and condition_livraison_libelle_langue.ref_libelle =  libelle.id_libelle and condition_livraison_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
        my $deliver_mode = $deliver[0];
	
	my @payement = $db->sqlSelect("libelle.libelle ", "condition_payement_libelle_langue,article, libelle, langue", "article.ref_condition_payement = condition_payement_libelle_langue.ref_condition_payement and id_article ='$article' and condition_payement_libelle_langue.ref_libelle =  libelle.id_libelle and condition_payement_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	my $payement_mode = $payement[0];
	$string .= "<tr><td align=\"left\" ><label>$SERVER{'payement_mode'}</LABEL></td><td align=\"left\"><input type=\"text\"  name=\"payement_mode\" value=\"$payement_mode\"><td></tr>";	
	$string .= "<tr><td align=\"left\" >$SERVER{'deliver_mode'}</td><td align=\"left\"><input type=\"text\"  name=\"deliver_mode\" value=\"$deliver_mode\" ></td></tr>";
}

sub loadFabricantProperties {	
	my $call = shift || '';
	my $string;
	my $fabricant = shift || '';
	my $libelle = shift || $SERVER{'fabricant'};
	my $enchere = shift || '';
	my $encherereur;
	if ($enchere) {	$encherereur= $articleClass->getLastEnchereurDetail();}
	$string .= "<tr><td align=\"left\">Fabricant</td><td align=\"left\"><input type=\"text\" name=\"fabricant\" value=\"$fabricant\" onchange=\"validateInput();\"></td>$encherereur</tr>";
	return $string;	
}

sub getCurrentMotoProperties {
    my $maincat = $query->param("category");
    my $subcat = $query->param("subcat");
    my $load = $query->param("isencher");
    my $name =$query->param("name");
    my $article = $query->param("article");
    my $string;
    my $clima;



    ($ARTICLE{'nb_cheveaux'},$ARTICLE{'nb_km'},$ARTICLE{' premiere_immatriculation '},
     $ARTICLE{'annee_construction'},$ARTICLE{'ref_limp_speed'},$ARTICLE{'climatisation'},$ARTICLE{'year_fab'},$ARTICLE{'ref_type_essence'})= $db->sqlSelect("nb_cheveaux,nb_km,premiere_immatriculation,annee_construction,ref_boite_de_vitesse,clima,annee,ref_type_essence",
				 "article,boite_de_vitesse_libelle_langue,type_essence_libelle_langue",
				 "id_article ='$article' and ref_boite_de_vitesse = id_boite_de_vitesse and essence_ou_diesel = id_type_essence");	


    my $type_essence = sqlSelect("libelle.libelle", "type_essence_libelle_langue, libelle, langue", "type_essence_libelle_langue.ref_libelle = '$ARTICLE{'ref_type_essence'}' AND type_essence_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my $ref_boite_de_vitesse = sqlSelect("libelle.libelle", "type_boite_de_vitesse_libelle_langue, libelle, langue", "type_boite_de_vitesse_libelle_langue.ref_libelle = '$ARTICLE{'ref_boite_de_vitesse'}' AND boite_de_vitesse_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");

    if ($ARTICLE{'climatisation'} eq '0') {$clima = $SERVER{'no'};}else {$clima = $SERVER{'yes'};}
    $string .="<tr>";$string .="<td align=\"left\" width=\"120\">$SERVER{'chev'}</td>";
    $string .="<td align=\"left\" width=\"120\"><input type=\"text\" name=\"horse\" value=\"$ARTICLE{'nb_cheveaux'}\"></td>";
    $string .="</tr>";$string .="<tr>";$string .="<td align=\"left\" width=\"120\">$SERVER{'nbr_km'}</td>";
    $string .="<td align=\"left\" width=\"120\"><input type=\"text\" name=\"km\" value=\"$ARTICLE{'nb_km'}\"></td>";
    $string .="</tr>";$string .="<tr>";$string .="<td align=\"left\" width=\"120\">$SERVER{'year_fabrication'}</td>";
    $string .="<td align=\"left\" width=\"120\"><input type=\"text\" name=\"year_fabrication\" value=\"$ARTICLE{'year_fab'}\"></td>";
    $string .="</tr>";$string .="<tr>";$string .="<td align=\"left\" width=\"120\">$SERVER{'year_service'}</td>";
    $string .="<td align=\"left\" width=\"120\"><input type=\"text\" name=\"year_service\" value=\"$ARTICLE{' premiere_immatriculation '}\"></td>";
    $string .= "</tr>";
    return $string;
}

sub loadButtonEncherir {
    my $string;
    my $invoke = shift || '';
    my $article_id = shift || '';
    $string .= "<input type=\"button\" value=\"Ench&eacute;rir\" onclick=\"openFormEncherir();\"/>";
    return $string;
}


sub loadButtonAcheter {
    my $string;
    my $invoke = shift || '';
    my $article_id = shift || '';
    $string .= "<input type=\"button\" value=\"Acheter\" onclick=\"openFormFirstTime();\"></input>";
    return $string;
}
sub loadButtonLouer {
    my $string;
    my $invoke = shift || '';
    my $article_id = shift || '';
    $string .= "<input type=\"button\" value=\"Louer\" onclick=\"openFormFirstTime();\"></input>";
    return $string;
}
sub loadStyle {
    my $string;my $style = shift || '';$string .= "<tr><td align=\"left\">$SERVER{'search_genre_label'}</td><td align=\"left\"><input type=\"text\" name=\"style\" value=\"$style\" onchange=\"validateInput()\"></td></tr>";return $string;
}

sub loadQuantityWanted {
    my $string;$string .= "<tr><td align=\"left\">$SERVER{'quantity_wanted'}</td><td align=\"left\"><input type=\"text\" name=\"quantity_wanted\" onchange=\"validateInput()\"></td></tr>";return $string;
}


sub loadWineProperties {
    my $article = $query->param("article");
	my $call = shift || '';
    $lang = $query->param("lang");
    loadLanguage();
	my $ref_cepage = shift || '';
	my $ref_pays_region_vin = shift || '';
	my $ref_type_de_vin = shift || '';
	my $provenance = shift || '';
	my $year = shift || '';
	$year = substr ($year,0,4);
	my ($pays_provenance ) = $db->sqlSelect("nom",  "pays_present",  "id_pays_present = '$provenance'");
	my ($type_de_vin) = $db->sqlSelect("libelle.libelle", "type_de_vin_libelle_langue,libelle,langue", "ref_type_de_vin = '$ref_type_de_vin' AND type_de_vin_libelle_langue.ref_libelle = libelle.id_libelle AND type_de_vin_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
	my ($cepage) = $db->sqlSelect("ref_cepage",  "article",  "id_article = $article");
	my $string;
	$string .= "<tr><td>$SERVER{'coutry_com'}</td><td><input type=\"text\" value=\"$pays_provenance\"></td></tr>";
	$string .= "<tr><td>$SERVER{'cepage'}</td><td><input type=\"text\" value=\"$cepage\"></td></tr>";
	$string .= "<tr><td>$SERVER{'millesim'}</td><td><input type=\"text\" value=\"$year\"></td></tr>";
	$string .= "<tr><td>$SERVER{'wine_t'}</td><td><input type=\"text\" value=\"$type_de_vin\"></td></tr>";
	return $string;
}

sub loadAuteur {
	my $call = shift || '';
	my $auteur = shift || '';
	my $year = shift || '';
	my $editor = shift || '';
	my $string;
	$string .= "<tr><td>Editeur</td><td><input type=\"text\" name=\"editor\" value=\"$editor\"></td></tr>";
	$string .= "<tr><td>Auteur</td><td><input type=\"text\" name=\"auteur\" value=\"$auteur\"></td></tr>";
	$string .= "<tr><td>Annee</td><td><input type=\"text\" name=\"year\" value=\"$year\"></td></tr>";
	return $string;
}

sub loadWearSize {
	my $string;
	my $invoke = shift || '';
	my $size = shift || '';
	$string .= "<tr><td>$SERVER{'size'}</td><td><input type=\"text\" name=\"size\" value=\"$size\"></td></tr>";
	return $string;
}

sub loadUsedOrNewDetail {
	my $string;
	my $caller = shift || '';
	my $used_value = shift || '';
	
	$string .= "<tr><td>$used_value</td><td><input type=\"text\" name=\"used\" value=\"$used_value\"></td></tr>";
	return $string;
}

sub loadSkypeLink {
	my $string;my $skype = shift || '';
	$string .= "<a href=\"callto://$skype\"><img alt=\"\" src=\"http://goodies.skype.com/graphics/skypeme_btn_small_green.gif\" style=\"border:1px;border-style:dotted;\"></a>";
	return $string;
}

sub loadDvdProperties {
	my $string;
	my $call = shift || '';
	my $actors = shift || '';my $realisator = shift || '';my $year = shift || '';my $duration = shift || '';
	$string .= "<tr><td>Acteur</td><td><input type=\"text\" name=\"actor\" value=\"$actors\"></td></tr>";
	$string .= "<tr><td>Realisator</td><td><input type=\"text\" name=\"realisator\" value=\"$realisator\"></td></tr>";
	$string .= "<tr><td>Annee</td><td><input type=\"text\" name=\"year_fabrication\" value=\"$year\"></td></tr>";
	$string .= "<tr><td>Duree</td><td><input type=\"text\" name=\"duration\" value=\"$duration\"></td></tr>";
	return $string;
}
sub loadSearchJardinValeur {
    my $string;
    $string .= "<input type=\"text\" name=\"valeur\" value=\"\"</input>";
    return $string;
}
sub loadDvdGenre {
	my $string;
	my $call = shift || '';
	my $genre = shift || '';
	$string .= "<tr><td>Genre</td><td><input type=\"text\" name=\"genre\" value=\"$genre\"></td></tr>";
	return $string;
}

sub loadSnowboardSize {
	my $string;
	my $call = shift || '';
	my $size = shift || '';
	$string .= "<tr><td>$SERVER{'size'}</td><td><input type=\"text\" name=\"size\" value=\"$size\"></td></tr>";
	return $string;
}

sub loadMsnMessengerLink {
	my $string;my $msn = shift || '';
	$string .= "<a href=\"msnim:chat?contact=$msn\"><img alt=\"\" src=\"../images/msn.jpg\" style=\"border:1px;border-style:dotted;\" height=\"18px\"></a>(need IE)";
	return $string;
}

sub loadDetailOffshoreProperties {
	my $call = shift || '';
	my $longueur = shift || '';
	my $largeur = shift || '';
	my $conso = shift || '';
	my $chev = shift || '';
	my $string;
    loadLanguage();
	$string .= "<tr><td>$SERVER{'longueur'}</td><td><input type=\"text\" name=\"longueur\" value=\"$longueur\"></td><td>$SERVER{'largeur'}</td><td align=\"left\"><input type=\"text\" name=\"largeur\" value=\"$largeur\" style=\"width:100px\"></td>";
	$string .= "</tr><tr><td>$SERVER{'chev'}</td><td><input type=\"text\" name=\"horse\" value=\"$chev\"></td></tr>";
	$string .= "<tr><td>$SERVER{'conso'}</td><td><input type=\"text\" name=\"conso\" value=\"$conso\"></td></tr>";
	return $string;
}
sub loadWat {
	my $wat = shift || '';my $string;
	$string .= "<tr><td>$SERVER{'wat'}</td><td><input type=\"text\" name=\"wat\" value=\"$wat\"></td></tr>";
	return $string;
}

sub loadLastBuyerOfThisArticle {
    my $string;my $article = $query->param("article");
    #$string .= "<td align=\"left\"></td><td align=\"left\"></td><td align=\"left\" width=\"200px\">$SERVER{'last_buyers_list'}</td>";
    #$string .="<td align=\"left\"><a href=\"#\" onclick=\"openFormLastBuyers();\" class=\"menulink\" >$SERVER{'see'}</a></td>";
    #$string .= "</tr>";
    return $string;
}

sub loadEnchereLastOffer {
    my $u = $query->param("u");
    my $string;my $article = $query->param("article");	
    $string .= "<td align=\"left\"></td><td align=\"left\"></td><td align=\"left\" width=\"200px\">$SERVER{'history_offer'}</td>";
    $string .="<td align=\"left\"><a href=\"#\"  onclick=\"openHistoriqueForm();closeFormLastBuyers();closeDetail();closeFormInsertComment();\" class=\"menulink\" >$SERVER{'see'}</a></td>";
    $string .= "</tr>";
    return $string;
}


sub loadMatosMain {
    #my  $index;my $table;
    #my  $session = new CGI::Session( "driver:File", $session_id,  {Directory=>"$session_dir"} );	
    #my  $username = $session->param("username");
    #my  ($matos) = sqlSelect("id_article, nom, pochette, prix ", "article, main_categorie_libelle_langue","ref_m
    
}
sub loadMakeEnchere {
    my $article = $query->param("article");
    ($ARTICLE{'max_enchere'})=$db->sqlSelect1("MAX(prix)", "enchere", "ref_article = '$article'");
    #$ARTICLE{'max_enchere'} += 1;
    my   $string = "";
		$string .="<tr>";
		$string .="<td align=\"left\"><label id=\"label_category_name\">$SERVER{'label_enchere'}</label></td>";				
     	        $string .= "<td align=\"left\"><input type=\"text\" name=\"encherepriceprice\" value=\"$ARTICLE{'max_enchere'}\"></td>";	       
    $string .= "</tr>";
    return $string;    
	
}
use Exporter ();
  
  
    @LoadProperties::ISA = qw(Exporter);
    @LoadProperties::EXPORT      = qw(create loadSearchBoatFabricant loadSearchWineFabricant loadSearchWearProperties loadAnimalSubCategory getAnimalCategories loadSearchWearCategories loadSearchWearFabricants loadSearchWearSubCategories loadMakeEnchere loadSearchJardinValeur loadSearchParfumValeur loadMatosMain loadQuantityWanted loadStyle loadUsedOrNewDetail loadIsBuyOrLocationValue loadWearSize loadEnchereLastOffer loadLastBuyerOfThisArticle loadWat loadDetailOffshoreProperties loadMsnMessengerLink loadSnowboardSize loadDvdGenre loadDvdProperties loadSkypeLink loadWineProperties loadCityLocationValue loadUsedOrNewDetail loadWearSize loadAuteur loadWineProperties  loadQuantityWanted loadStyle loadDetailInfoPcProperties loadDimensionOther getLinkImmobilierInterest loadPayementModeProperties loadFabricantProperties getCurrentMotoProperties loadFabricantProperties loadPayementModeProperties loadDetailInfoPcProperties loadDimensionOther  getCurrentCarProperties getCategoryID loadUsedOrNew loadAutor loadAddWineType loadAddWineCepage loadAddWineRegion loadAddGamesType  loadOffshoreProperties loadAddImmoDepartement loadAddImmoCanton loadAddImmoCountry loadAddWineCountry loadQuantity loadInfoPcProperties loadTvDimension timeDiff loadCityLocation getCarProperties loadFabricant loadTypeEcran getIsEnchere loadIsBuyOrLocation loadEnchereProperties getCategoryGo loadSubCategoriesOther loadRegisterLongerTypeAccount loadRegisterLongerPrice getSelectArticleDepot getWearType  getWearSex loadMenu getAutoType  getInformatiqueType getTvVideoType getNatelType getArticleCat loadSearchBookProperties loadSearchBookCategories loadCantonImmoMain loadImmobilierLocationType  loadImmobilierMenu getCategoryGoAddWish loadBuyOrLocation  localHabitableSurface localNbrFloor loadLocationVilla loadSearchTvProperties loadTvFabricant loadTvTypeEcran loadTvOrDVD loadMotoSearchProperties loadSearchMotoSubCategory loadSearchMotoCategory  loadMotoFabricant loadAutoSearchProperties loadAutoFabricant loadWineType loadWineCountry loadSearchCdUsed loadSearchWineCepage loadSearchWineRegion  loadSearchWineCountry loadWatchAndJewelsByIndex loadParfumSubCategory loadParfumCategory  loadChocolatMenu loadCigaresSubCategories  loadWatchSubCategory loadWatchCategory loadBoatMenu  loadEncherePropertiesDealAgain getIsEnchereDealAgain loadSearchCdProperties loadSearchCdVinylMixTapeSubCategories loadSearchCdVinylMixTapeCategories loadCdVinylMixTapeSubCategories loadCdVinylMixTapeCategories sub loadSearchWearJeansProperties loadWearFabricant getSearchWearType  getSearchWearSex loadSearchInfoPcProperties   loadSearchInfoEcranDimension loadInfoCategory loadInfoFabricant loadAppartBuy loadLoyer loadSearchImmoMode loadSearchImmoDepartement loadSearchUsed loadSearchWatchFabricant loadBookByIndex loadBookIndex  loadBookCategories  loadDvdCategories loadAstroIndex loadAstroSubCategory loadAstroCategory  loadGamesType  loadGamesSubMenu loadGamesMenu getBabySubCategory getBabyCategory  loadCalendrierIndex getCalendrierSearchSubCategory  getCalendrierCategory getMotoSubCategory getMotoCategory loadArtByIndex  loadArtIndex  getArtAndDesignSubCategory getArtAndDesignCategory  loadSportSubMenu loadSportMenu  loadSearchSportProperties  loadSearchSportSubMenu loadSearchSportMenu loadSearchDvdProperties loadSearchDvdCategories loadSearchJardinUsed getUserID loadSearchGamesUsed loadEditor loadSearchGamesType  loadSearchGamesSubMenu loadSearchGamesMenu loadSearchBoatCategories loadSearchCigaresProperties loadSearchWatchFabricant loadSearchWatchProperties loadSearchCigaresFabricant  loadSearchCigaresCategories  loadSearchWatchCategory loadSearchWatchSubCategory loadSearchWatchSubCategory  loadSearchImmoCanton loadImmobilierType loadSearchImmoCountry loadSearchParfumFabricant loadSearchParfumSubCategory loadSearchParfumCategory loadSearchLingerie loadSearchLingerieFabricant loadSearchLingerieSubCategory loadSearchLingerieCategory loadSearchBabyFabricant loadSearchBabySubCategory loadSearchBabyCategory loadSearchCalendarSubCategory loadSearchCalendarCategory loadSearchJardinSubCategory loadSearchJardinCategory loadSearchCollectionFabricant loadSearchInstruments loadSearchInstrumentsFabricant  loadSearchInstrumentsCategory loadSearchCollectionSubCategory loadSearchCollectionCategory loadSearchAnimalSubCategory loadSearchAnimalCategory loadSearchArtSubCategory loadSearchArtCategory loadHabitatJardinSubCategory loadHabitatJardinCategory loadLingerieSubCategory loadLingerieCategory loadInstrumentCategory  loadCityLocationValue getLinkImmobilierInterest loadIsBuyOrLocationValue trimwhitespace);
    @LoadProperties::EXPORT_OK   = qw(); 

1;	