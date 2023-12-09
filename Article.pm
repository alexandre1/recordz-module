package Article;
#use warnings;
use MyImageManipulation;
use MyDB;
use SharedVariable;
use TableArticle;
#use LoadProperties;
use MyDB;
use CGI;
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);
use Time::HiRes qw(gettimeofday);
use Compress::Zlib;
use CGI::Session qw/-ip-match/;

use vars qw (%ENV $session_dir $can_do_gzip $cookie $page $dir $dirLang $dirError $imgdir $action $t0 $session_id $ycan_do_gzip $current_ip $lang $LANG %ARTICLE %SESSION %SERVER %USER $CGISESSID %LABEL %ERROR %VALUE $COMMANDID %COMMAND %DATE %PAYPALL $INDEX %LINK  $query $session $host $t0  $client);

$query = CGI->new ;
$cookie = "";
$current_ip = $ENV{'REMOTE_ADDR'};
$client = $ENV{'HTTP_USER_AGENT'};
$t0 = gettimeofday();
$host = "http:/127.0.0.1";
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
my $mydb = MyDB->new;
my $imageManinpulation = MyImageManipulation->new;
my $tableArticle = TableArticle->new;
my $the_key = "otherbla";
#load html label
loadLanguage ();
#load error label
loadError();

sub createArticle {
        my $class = shift;
        my ($opts)= @_;
	my $self = {};
	return bless $self, $class;
}
sub loadError {
    if (defined $query) { 
		$lang = lc ($query->param('lang'));
		open (FILE, "<$dirError/$lang.error.conf") or die "cannot open file $dirError/$lang.error.conf";    
		while (<FILE>) {
			(my  $label, my  $value) = split(/=/);
			$SERVER{$label} = $value;	
		}
		close (FILE);
		}
}

sub loadLanguage {
	if (defined $query) { 
		$lang = $query->param("lang");
		$lang = lc ($lang);
		open (FILE, "<$dirLang/$lang.conf") or die "cannot open file $dirLang/$lang.conf";    
		
		while (<FILE>) {
		(my  $label, my  $value) = split(/=/);
			$SERVER{$label} = $value;
		}
		close (FILE);
	}
}



sub loadArticleSelection {
    $lang = $query->param("lang") ;	
    my  $cat = shift || '';
    my  $type = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  $add;
    my  $add2;
    my  $dep;
    my  %OPTIONS = ();
    my $counter = 0;
	my  ($c)= $mydb->sqlSelect("count(DISTINCT article.nom,marque,label,prix, pochette)",
			   "article,met_en_vente",
			   "ref_article = id_article AND met_en_vente.notre_selection = '1' AND ref_statut = '3' AND article.quantite > 0");	
	my $counter = $c;
	my $total = $c;
		
	
	my $first_page = 0;
	my $count_per_page = 40;
	my $counter = ($total / $count_per_page); #Should be get from db;
	my $min_index = $query->param("min_index");
	if (not defined $min_index) {
		$min_index = 0;
	}
	my $content = "";
	my $max_index = $query->param("max_index");	
	if (not defined $max_index) {		
		$max_index = 40;
	} else {
		#$max_index = round ($counter / 40, 1);#Number of objects displayed per page.
	}		
	my $last_page = $nb_page - 1;
	my $n2 = 0;

	my $index_page = $query->param("index_page");
	if (not defined $index_page) {
		$index_page = 0;
	}
	my $previous_page = $query->param("previous_page");	
	if (not defined $previous_page) {
		$index_page = 0;
		$previous_page = 0;
	}
	
	$string .= "<a href=\"/cgi-bin/main.pl?min_index=0&amp;max_index=40&amp;index_page=$index_page&page=main&amp;lang=$lang&amp;page=main&session=$session_id&amp;min_index_our_selection=$min_index&amp;max_index_our_selection=$max_index\" ><-First page-></a>&#160;&nbsp;";				
	
	if (($index_page -1) > 0) {
		$previous_page = $previous_page - 1;
		$index_page--;
		$index--;
		$min_index = $min_index -40;
		$max_index = $max_index -40;
		$string .= "<a href=\"/cgi-bin/main.pl?lang=$lang&amp;page=main&session=$session_id&amp;min_index_our_selection=$min_index&amp;max_index_our_selection=$max_index&amp;previous_page=$previous_page&amp;index_page=$index_pagex&amp;previous_page=$previous_page\" ><-Previous-></a>&#160;&nbsp;";				
	}
	for my $index ($min_index..$counter) {						
		$next_page = $min_index + 40;
		if ($index_page < $count_per_page) {
			if (($index_page % $count_per_page) > 0) {							
				$string .= "<a href=\"/cgi-bin/main.pl?lang=$lang&amp;page=main&session=$session_id&amp;min_index_our_selection=$min_index&amp;max_index_our_selection=$max_index&amp;previous_page=$previous_page&amp;index_page=$index_pagex&amp;previous_page=$previous_pagee&amp;index_page=$index_page\"\" ><-$index_page-></a>&#160;&nbsp;";								

			}
		}		
		$index_page++;
		$index++;
		$counter--;
		$min_index += 40;;						
		$max_index += 40;;					
	}	
	$string .= "<a href=\"/cgi-bin/main.pl?lang=$lang&amp;page=main&session=$session_id&amp;min_index_our_selection=$min_index&amp;max_index_our_selection=$max_index&amp;min_index=$min_index&amp;max_index=$max_index&amp;previous_page=$previous_page&amp;next_page=$next_page\" ><-Next></a>&#160;&nbsp;";				      
	return $string;    
}

sub getConditionPayement {
    my $u = $query->param("u");
    my $lang = $query->param("lang");
    my  ($c)= $mydb->sqlSelectMany("libelle.libelle",
			   "condition_payement_libelle_langue,langue, libelle",
			   "ref_condition_payement = condition_payement_libelle_langue.ref_condition_payement AND condition_payement_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' AND condition_payement_libelle_langue.ref_libelle = libelle.id_libelle");
    my  $string ;
    $string .= "<tr>";
    $string .= "<td align=\"left\">$SERVER{'condition_payement'}</td>";
    $string .= "<td align=\"left\"><select name=\"condition_payement\">";
    my  %OPTIONS = ();
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option>$OPTIONS{'category'}</option>";
	}
    $string .= "</select></td>";
    $string .= "</tr>";
    return $string;    
}
sub getCat {
    my $lang = $query->param("lang");
     my  ($c)= $mydb->sqlSelectMany("libelle",
			   "categorie_libelle_langue,libelle, langue",
			   "langue.key = '$lang' AND categorie_libelle_langue.ref_langue = langue.id_langue AND categorie_libelle_langue.ref_categorie = categorie_libelle_langue.ref_categorie AND categorie_libelle_langue.ref_libelle = libelle.id_libelle");	
    
    my  $string = "";
    while( ($ARTICLE{'state'})=$c->fetchrow()) {
	    $string .= "<option>$ARTICLE{'state'}</option>";
	}
	return $string;
	
}

sub getConditionLivraison {
    my $lang = $query->param("lang");
    my  ($c)= $mydb->sqlSelectMany("libelle.libelle",
			   "condition_livraison_libelle_langue,libelle, langue",
			   "condition_livraison_libelle_langue.ref_libelle = libelle.id_libelle AND condition_livraison_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my  $string ;
    $string .= "<tr>";
    $string .= "<td align=\"left\">$SERVER{'condition_livraison'}</td>";
    $string .= "<td align=\"left\"><select name=\"condition_livraison\">";
    my  %OPTIONS = ();
    while(($OPTIONS{'category'})=$c->fetchrow()) {
	
         $string .= "<option>$OPTIONS{'category'}</option>";
	}
    $string .= "</select></td>";
    $string .= "</tr>";
    return $string;    
}

sub viewArticleSelectionByIndex {
    my  $cat = shift || '';
	loadLanguage();
    my  $type = shift  || '';
    my  $depot = $query->param("depot") ;
    $lang = $query->param("lang") ;
    my  $index_start = $query->param ("min_index_our_selection");
    my  $index_end = $query->param ("max_index_our_selection");
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $string = "";
    my  $add;		
    my  $add2;
    my  $dep;
    my $add3 ="";

    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");
    if (!$index_start ) {
	$index_start = 0;
    }
    if (!$index_end ) {
	$index_end = 40;
    }
    if ($country_swiss eq '1') {
	$add .= " AND article.ref_pays = 1";
    }
    if ($country_france eq '1') {
	if ($country_swiss) {
		$add .= " OR article.ref_pays = 2";
	}else {
		$add .= " AND article.ref_pays = 2";
	}
    }
									
    my  ($c)= $mydb->sqlSelectMany("article.nom,id_article,marque,prix, categorie_libelle_langue.ref_categorie,pochette ",
		       "article,met_en_vente,categorie_libelle_langue",
		       "ref_article = id_article  AND met_en_vente.notre_selection = '1' AND ref_statut = '3' and met_en_vente.page_principale = 'on' AND article.quantite > 0 and article.enchere_date_fin > '$date $time' AND categorie_libelle_langue.ref_categorie = article.ref_categorie $add  ORDER BY id_article DESC LIMIT $index_start, $index_end");	
    
    my $i = 0;
    my $j = 0;
	#print "Content-Type: text/html\n\n";
	#print $c;
	$string = "<table style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><tr style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"151\">$SERVER{'article_name_label'}</td><td align=\"left\">$SERVER{'fabricant'}</a></td><td align=\"left\">$SERVER{'article_price_label'}</td></tr>";
    

    
    
    while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'author'},$ARTICLE{'price'},$ARTICLE{'ref_categorie'},$ARTICLE{'image'})=$c->fetchrow()) {
	if ($ARTICLE{'image'} eq '') {
		##$ARTICLE{'image'} = "../images/blank.gif";
	}
        if ($ARTICLE{'ref_categorie'}) {
            $ARTICLE{'genre'} = $mydb->sqlSelect ("libelle.libelle","categorie_libelle_langue, libelle, langue","categorie_libelle_langue.ref_categorie = '$ARTICLE{'ref_categorie'}' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
        }
        
	$string .= "<tr><td align=\"left\"><img alt=\"\"  src=\"$ARTICLE{'image'}\" onClick='window.open('$ARTICLE{'image'}')';' \"></td><td align=\"left\"><a href=\"/cgi-bin/detail.pl?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'author'}</td><td align=\"left\">$ARTICLE{'price'} CHF</td></tr>";
    }
    $string .="</table>";    
    return $string;
}

sub arrondi {
    my $n = shift || '';
    my $arrondi = sprintf("%.0f", $n);    
    return $arrondi;
}

sub get_day_in_same_week {
    my  $dt            = shift;
    my  $cible         = shift;
    
    my  $debut_semaine = shift || 1;

    my  $wday = ($dt->day_of_week() - $debut_semaine + 7) % 7;
    $cible = ($cible - $debut_semaine + 7) % 7;
    return $dt->clone()->add(days => $cible - $wday);
  }


sub weekNews {
	my $string;
	my  $date = DateTime->today();
	my  $start_of_week = get_day_in_same_week($date,1,1);
	$start_of_week = substr($start_of_week, 0, 10);	
	my  $end_of_week = get_day_in_same_week($date,7,1);
	$end_of_week = substr($end_of_week, 0, 10);
	$date = substr($date, 0, 10);
   
        my  ($c)= $mydb->sqlSelectMany("DISTINCT article.nom,marque,label,prix, libelle.libelle",
			   "article, met_en_vente, genre, categorie, depot, libelle",
			   "ref_article = id_article and ref_categorie = id_categorie AND ref_genre = id_genre and id_article = id_article AND article.ref_statut = '3' AND date >= '$start_of_week' AND date <= '$end_of_week' LIMIT 1, 5");	
	
	while( ($ARTICLE{'name'},$ARTICLE{'author'},$ARTICLE{'label'},$ARTICLE{'price'},$ARTICLE{'genre'})=$c->fetchrow()) {
		$ARTICLE{'name'} = uc ($ARTICLE{'name'});
		$string .= "---(<b><a style=\" color:#CC66FF\" href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&amp;action=detail&amp;article=$ARTICLE{'name'}\">$ARTICLE{'name'}</a></b></label>&nbsp;$ARTICLE{'author'}<label style=\" color=:#CC66FF\">&nbsp;<b>$ARTICLE{'genre'}</b></label> \)--";
	}
	return $string;
}

sub getImagesForDetails {
	my $article = $query->param("article");my $string;
	$string .= "<img alt=\"\" src=\"../upload/thumb.$article.2.jpg\" border=\"1\" width=\"50px\" height=\"37px\" onclick=\"window.open('/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&action=show_image2&amp;image=$article.2.jpg','MyWindow','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=no,width=750,height=385,left=20,top=20')\">" if (-e "$imgdir/thumb.$article.2.jpg");
	$string .= "&nbsp;<img alt=\"\" src=\"../upload/thumb.$article.3.jpg\" border=\"1\" width=\"50px\" height=\"37px\" onclick=\"window.open('/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&action=show_image2&amp;image=$article.3.jpg','MyWindow','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=no,width=750,height=385,left=20,top=20')\">" if (-e "$imgdir/thumb.$article.3.jpg");
	$string .= "&nbsp;<img alt=\"\" src=\"../upload/thumb.$article.4.jpg\" border=\"1\" width=\"50px\" height=\"37px\" onclick=\"window.open('/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&action=show_image2&amp;image=$article.4.jpg','MyWindow','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=no,width=750,height=385,left=20,top=20')\">" if (-e "$imgdir/thumb.$article.4.jpg");
	return $string;	
}
sub getArticleDetailCount {
	my $article = $query->param("article");
	my $current_addr = $ENV{REMOTE_ADDR};
	my  @f = $mydb->sqlSelect("visites ", "article","id_article= '$article'");
	my $counter = $f[0];
	if ($counter eq '') {
	    $counter = 1;
	}

	my $update = '1';
	my  ($c)= $mydb->sqlSelectMany("DISTINCT ip","article_ip","ref_article = '$article'");

	while( ($ARTICLE{'ip'})=$c->fetchrow()) {
		if ($ARTICLE{'ip'} eq $current_addr) {
		    $update = '0';
		}else {
		     $update = '1';
		}
	    }
		if ($update eq '1'){
		    $counter++;
            $mydb->sqlUpdate("article","id_article = $article",(visites => "$counter"));
		    $mydb->sqlInsert("article_ip",								
							ref_article		=> $article,
							ip			=> $current_addr
						);
				
		}
	
		return $counter;
}

sub getArticleEnchereCount {
	my $article = $query->param("article");
	my  @f = $mydb->sqlSelect("nbr_enchere", "article","id_article= '$article'");
	my $counter = $f[0];return $counter;
}


sub getLinkPurchaseOther {
	my $article = $query->param("article");my $string ;
	my  @d = $mydb->sqlSelect("enchere ", "article","id_article= '$article'");
	my  $is_enchere = $d[0];
	if ($is_enchere eq '0') {

		$string .= "<a href=\"#self\" onClick=\"Lvl_P2P('/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&action=addtobasket&article=$article',true,0500)\" class=\"menulink\" >$SERVER{'direct_payement'}</a>&nbsp;<br />";
	}else {
		$string .= "<img alt=\"\" src=\"../images/encherir.gif\" onclick=\"ench();\" style=\"border:1px;border-style:dotted;\">";
	}	
	
	return $string;
}

sub loadEnchereLastOffer {
    my $string;my $article = $query->param("article");	
    $string .= "<td align=\"left\"></td><td align=\"left\"></td><td align=\"left\" width=\"200px\">$SERVER{'history_offer'}</td>";
    $string .="<td align=\"left\"><a href=\"#\" onclick=\"openFormHistorique();\" class=\"menulink\" >$SERVER{'see'}</a></td>";
    $string .= "</tr>";
    return $string;
}

sub loadMakeEnchere {
    my $article = $query->param("article");
    ($ARTICLE{'max_enchere'})=$mydb->sqlSelect("MAX(prix)", "enchere", "ref_article = '$article'");
    $ARTICLE{'max_enchere'} += 1;
    my   $string = "";
		$string .="<tr>";
		$string .="<td align=\"left\"><label id=\"label_category_name\">$SERVER{'label_enchere'}</label></td>";				
     	        $string .= "<td align=\"left\"><input type=\"text\" name=\"encherepriceprice\" value=\"$ARTICLE{'max_enchere'}\"></td>";	       
    $string .= "</tr>";
    return $string;    
	Sp
}

sub getEnchereCounter {
	my $nbr_enchere = shift || '';my $article = $query->param("article");
	my  @f = $mydb->sqlSelect("nbr_enchere", "article","id_article= '$article'");
	my $counter = $f[0];
	my $string;
	$string .= "<td align=\"left\" width=\"200\"><label id=\"label_category_name\">$SERVER{'nbr_enchere'}</label></td>";			
	$string .= "<td align=\"left\"><label id=\"label_category_name\"><input type=\"text\" value=\"$counter\"></td>";
	return $string;
}

sub getLastEnchereTable {
	my $string;my $article = $query->param("article");
	$ARTICLE{'max_enchere'} = '0';
	($ARTICLE{'max_enchere'})=$mydb->sqlSelect("MAX(prix)", "enchere", "ref_article = '$article'");
	$string .= "<td align=\"left\" width=\"200\"><label id=\"label_category_name\">$SERVER{'last_enchere_price'}</label></td>";			
	$string .= "<td align=\"left\"><label id=\"label_category_name\"><input type=\"text\" value=\"$ARTICLE{'max_enchere'}\"></label></td>";			
	return $string;
}

sub getLastEnchereurDetail {
	my $string;my $article = $query->param("article");
	my $ref_max_enchereur;
	my $max_enchere;
	($ARTICLE{'max_enchere'})=$mydb->sqlSelect("MAX(prix)", "enchere", "ref_article = '$article'");
	if ($ARTICLE{'max_enchere'} ne '') {
        	($ARTICLE{'max_enchereur'},$ARTICLE{'id_enchere'})=$mydb->sqlSelect("ref_enchereur,id_enchere", "enchere", "ref_article = '$article' AND prix = $ARTICLE{'max_enchere'}");    
		($ARTICLE{'nom_utilisateur_acheteur'},$ARTICLE{'email_acheteur'},$ARTICLE{'acheteur_lang'},$ARTICLE{'acheteur_adresse'},$ARTICLE{'acheteur_ville'},$ARTICLE{'acheteur_npa'},$ARTICLE{'acheteur_telephone'},$ARTICLE{'acheteur_nom'},$ARTICLE{'acheteur_prenom'})= $mydb->sqlSelect("nom_utilisateur,email,lang,adresse,ville,npa,no_telephone,nom,prenom", "personne", "id_personne = '$ARTICLE{'max_enchereur'}'");
	}
	$string .= "<td align=\"left\" width=\"200\"><label id=\"label_category_name\">$SERVER{'last_enchereur'}</label></td>";			
	$string .= "<td align=\"left\"><a href=\"/cgi-bin/detail_dealer.pl?lang=$lang&amp;session=$session_id&page=profil_vendeur&username=$ARTICLE{'nom_utilisateur_acheteur'}\" class=\"menulink\" >$ARTICLE{'nom_utilisateur_acheteur'}</a></label></td>";			
	return $string;
}

sub evalDealView {
    my $string;
	my $string2;
    my $content;
    my $username = $query->param("username");
	$lang = $query->param("lang");
	loadLanguage();
    my $index_a = $tableArticle->loadEvalBuyPositivIndex();
    my $table_a = $tableArticle->loadEvalBuyPositivTable();    
    my $index_b = $tableArticle->loadEvalBuyNegativIndex();
    my $table_b = $tableArticle->loadEvalBuyNegativTable();    
    open (FILE, "<$dir/evaldealview.html") or die "cannot open file $dir/evaldealview.html";
	while (<FILE>) {	
	    s/\$ERROR{'([\w]+)'}/ exists $ERROR{$1} ? $ERROR{$1} : $1 /eg; 
	    s/\$LANG/$lang/g;
	    s/\$ARTICLE{'evaldealviewindex'}/$index_a/g;
	    s/\$ARTICLE{'evaldealviewtable'}/$table_a/g;
	    s/\$ARTICLE{'evaldealviewnegindex'}/$index_b/g;
	    s/\$ARTICLE{'evaldealviewnegtable'}/$table_b/g;	    
	    s/\$ERROR'([\w]+)'}/ exists $ERROR{$1} ? $ERROR{$1} : $1 /eg; 
	    $content .= $_;	
	}
	return $content;
}

sub doDealerIndex {
    my $option = $query->param("enchere");
    my $dealer = $query->param("username");
    my $vendu = $query->param("vendu");
    my  $from = "article";
    my  $where;
    my $string;
    #doDealerIndex
    my  $total = '0';
    
    my  ($c)= $mydb->sqlSelectMany("DISTINCT article.nom,id_article,pochette","personne,met_en_vente, article","nom_utilisateur = '$dealer' AND met_en_vente.ref_vendeur = id_personne AND met_en_vente.ref_article = article.id_article AND article.enchere = '$option' AND article.vendu = '$vendu'");
    while( ($ARTICLE{'name'})=$c->fetchrow()) {
	    $total +=1;
	}
    
	$min_index += 40;	
	my $counter = ($total / 40); #Should be get from db;
	my $string = "";
	my $first_page = 0;
	my $nb_page = 0;
	my $min_index = $query->param("min_index");
	if (not defined $min_index) {
		$min_index = 0;
	}
	my $count_per_page = 10;
	my $content = "";
	my $max_index = $query->param("max_index");	
	if (not defined $max_index) {		
		$max_index = 40;
	} else {
		#$max_index = round ($counter / 40, 1);#Number of objects displayed per page.
	}		
	my $last_page = $nb_page - 1;
	my $n2 = 0;

	my $index_page = $query->param("index_page");
	if (not defined $index_page) {
		$index_page = 0;
	}
	my $previous_page = $query->param("previous_page");	
	if (not defined $previous_page) {
		$index_page = 0;
		$previous_page = 0;
	}
	my $index = 0;
#	$string .= "<a href=\"/cgi-bin/pagination.pl?lang=FR&amp;session=1\" ><-\"First page\"-></a>&#160;&nbsp;";				
	$string .= "<a href=\"/cgi-bin/detail_dealer.pl?lang=$lang&amp;session=$session_id&page=profil_vendeur&username=$dealer&enchere=$option&min_index0&max_index=40&amp;previous_page=$previous_page&amp;index_page=$index_page\ class=\"menulink2\" >First page</a>&#160;&nbsp;";				
	if (($index_page -1) > 0) {
		$previous_page = $previous_page - 1;
		$index_page--;
		$index--;
		$min_index = $min_index -40;
		$max_index = $max_index -40;
		#$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&page=profil_vendeur&username=$dealer&enchere=$option&min_index=$min_index&max_index=$max_index\"  class=\"menulink2\" ><-$i-></a>&#160;&nbsp;";		
		$string .= "<a href=\"/cgi-bin/detail_dealer.pl?lang=$lang&amp;session=$session_id&page=profil_vendeur&username=$dealer&enchere=$option&min_index=$min_index&max_index=$max_index&amp;previous_page=$previous_page&amp;index_page=$index_page\ class=\"menulink2\" ><-\"$i\"-></a>&#160;&nbsp;";				
	}
	for my $index ($min_index..$counter) {						
		$next_page = $min_index + 40;
		if ($index_page < $count_per_page) {
			if (($index_page % $count_per_page) > 0) {							
				$string .= "<a href=\"/cgi-bin/detail_dealer.pl?lang=$lang&amp;session=$session_id&page=profil_vendeur&username=$dealer&enchere=$option&min_index=$min_index&max_index=$max_index&amp;previous_page=$previous_page&amp;index_page=$index_page\ class=\"menulink2\"  ><-$index_page-></a>&#160;&nbsp;";				
			}
		}		
		$index_page++;
		$index++;
		$counter--;
		$min_index += 40;;						
		$max_index += 40;;					
	}
	$string .= "<a href=\"/cgi-bin/detail_dealer.pl?lang=$lang&amp;session=$session_id&page=profil_vendeur&username=$dealer&enchere=$option&min_index=$min_index&max_index=$max_index&amp;previous_page=$previous_page&amp;index_page=$index_page\ class=\"menulink2\"  ><-Next-></a>&#160;&nbsp;";				
	return $content;
}
#load search index result

sub doDealerIndexed {
    my $option = $query->param("enchere");
    my $dealer = $query->param("username");
    my $vendu = $query->param("vendu");
    my  $index_start = $query->param ("min_index") ;
    my  $index_end = $query->param ("max_index");
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d",$year+1900,$mon+1,$mday;
    
    if (!$index_start ) {
	$index_start = 0;
    }
    if (!$index_end ) {
	$index_end = 40;
    }
   my  $string = "<table style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><tr<td align=\"left\" width=\"51\"></td><td align=\"left\" width=\"151\"></td><td align=\"left\"></a></td><td align=\"left\"></td></tr>";
   my  ($c)= $mydb->sqlSelectMany("DISTINCT article.nom,id_article,pochette,prix","personne,met_en_vente, article","nom_utilisateur = '$dealer' AND met_en_vente.ref_vendeur = id_personne AND met_en_vente.ref_article = article.id_article AND article.enchere = '$option' AND article.vendu = '$vendu' LIMIT $index_start, $index_end");
	 while( ($ARTICLE{'nom'},$ARTICLE{'id_article'},$ARTICLE{'pochette'},$ARTICLE{'prix'})=$c->fetchrow()) {
		$string .= "<tr><td align=\"left\"><img alt=\"\" src=\"$ARTICLE{'pochette'}\"></td><td align=\"left\"><a href=\"/cgi-bin/detail.pl?username=$dealerde&amp;lang=$lang&amp;session=$session_id&amp;action=detailother&amp;article=$ARTICLE{'id_article'}\" class=\"menulink\" >$ARTICLE{'nom'}</a></td><td>$ARTICLE{'prix'}</td></tr>";
	}
    $string .="</table>";    
    return $string;
}

sub loadCommentaireIndex {
    my  $article = $query->param("article");
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my ($c)= $mydb->sqlSelectMany("nom_utilisateur,question,texte,date",
			   "commentaire, personne",
			   "ref_article = $article and ref_emetteur = id_personne");	
	
	while( ($ARTICLE{'nom_utilisateur'},$ARTICLE{'question'},$ARTICLE{'texte'},$ARTICLE{'date'})=$c->fetchrow()) {
	    $total +=1;
	}

	my $counter = $total;
	my $string = "";
	my $first_page = 0;
	my $nb_page = 0;
	my $min_index = $query->param("min_index");
	if (not defined $min_index) {
		$min_index = 0;
	}
	my $count_per_page = 10;
	my $content = "";
	my $max_index = $query->param("max_index");	
	if (not defined $max_index) {		
		$max_index = 40;
	}	
	my $last_page = $nb_page - 1;
	my $n2 = 0;

	my $index_page = $query->param("index_page");
	if (not defined $index_page) {
		$index_page = 0;
	}
	my $previous_page = $query->param("previous_page");	
	if (not defined $previous_page) {
		$index_page = 0;
		$previous_page = 0
	}
	my $index = 0;
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&amp;min_index=$min_index&amp;max_index=$max_index&action=detailother&article=$article&viewcommentaire=1&amp;previous_page=$previous_page\" class=\"menulink2\" ><-First page-></a>&#160;&nbsp;";				
	if (($index_page -1) > 0) {
		$previous_page = $previous_page - 1;
		$index_page--;
		$index--;
		$min_index = $min_index -40;
		$max_index = $max_index -40;
		$string .= "<a href=\"/cgi-bin/pagination.pl?lang=FR&amp;session=1;min_index=$min_index&amp;max_index=$max_index&amp;previous_page=$previous_page&amp;index_page=$index_page\" ><-Previous-></a>&#160;&nbsp;";				
	}
	for my $index ($min_index..$max_index) {						
		$next_page = $min_index + 40;
		if ($index_page < $count_per_page) {
			if (($index_page % $count_per_page) > 0) {							
				$string .= "<a href=\"/cgi-bin/pagination.pl?lang=FR&amp;session=1&amp;min_index=$min_index&amp;max_index=$max_index&amp;index_page=$index_page&amp;previous_page=$previous_page&amp;index_page=$index_page\" ><-$index_page-></a>&#160;&nbsp;";				
			}
		}		
		$index_page++;
		$index++;
		$min_index += 40;;						
		$max_index += 40;;					
	}
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&amp;min_index=$min_index&amp;max_index=$max_index&action=detailother&article=$article&viewcommentaire=1&amp;previous_page=$previous_page\" class=\"menulink2\" ><-Next-></a>&#160;&nbsp;";				
	return $string;    
}

sub round {
    my $n = shift || '';
    my $r = sprintf("%.0f", $n);    
    return $r;
}

sub viewCommentaireByIndex {
    my $article = $query->param("article");
    my  $cat = shift || '';
    my  $type = shift  || '';
    my  $depot = $query->param("depot") ;
    my  $index_start = $query->param ("min_index");
    my  $index_end = $query->param ("max_index");
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);

    my  $string = "";
    my  $add;
    my  $add2;
    my  $dep;
    
    if (!$index_start ) {
	$index_start = 0;
    }
    if (!$index_end ) {
	$index_end = 40;
    }

    if ($cat) {
	$add = "AND genre.genre = '$cat'";
    } else {
	$add = "";
    }
    if ($type) {
	$add2 = "AND id_categorie = '$type'";
    } else {
	$add2 = "";		
    }

    if ($depot) {
	$dep = "AND ref_depot = (SELECT id_depot FROM depot WHERE ville = '$depot')";
    }

    my  ($c)= $mydb->sqlSelectMany("nom_utilisateur,question,texte,date",
		        "commentaire, personne",
		       "ref_article = $article and ref_emetteur = id_personne LIMIT $index_start, $index_end");	
    

    my $i = 0;
    my $j = 0;
    $string .= "<table style=\"border-bottom:3px; border-left:3px; border-right:3px; border-top:3px; border-style:dotted;border-color:#94CEFA;\"><tr>";
    $string .= "<tr>";
    while( ($ARTICLE{'nom_utilisateur'},$ARTICLE{'question'},$ARTICLE{'texte'},$ARTICLE{'date'})=$c->fetchrow()) {
	#$string .= " <label>&nbsp;&nbsp;$ARTICLE{'genre'}</label>";
	if ($ARTICLE{'pochette'} eq '') {
		$ARTICLE{'pochette'} = "../images/no.gif";
	}
	$ARTICLE{'label'} = substr($ARTICLE{'label'},0, 18);
	$ARTICLE{'label'} .= "...";
	$string .= "<td align=\"left\" width=\"300px\" style=\"border-style:dotted;border-width:thin;border-color:#94CEFA\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&amp;page=profil_vendeur&username=$ARTICLE{'nom_utilisateur'}\" class=\"menulink\" >$ARTICLE{'nom_utilisateur'}</a><br/>$ARTICLE{'question'}<br/>$ARTICLE{'texte'}<br/>$ARTICLE{'date'}</td>";
	$string .= "</tr>";
    }
    $string .= "</table>";
    return $string;
    
}

sub clearBasket {
	my  $username = shift || '';
	
	if ($username) {
		my  ($c) = $mydb->sqlSelectMany("id_commande", "commande","client_ref = (SELECT id_personne FROM personne WHERE nom_utilisateur = '$username') AND date_payement is null");		
		
		while (my  ($id_commande)=$c->fetchrow()) {
			my  ($d) = $mydb->sqlSelectMany("id_article", "commande,commande_article,article","client_ref = (SELECT id_personne FROM personne WHERE nom_utilisateur = '$username') AND commande.date_payement is null AND id_article = ref_article");		
			while (my  ($id_article)=$d->fetchrow()) {			
				$mydb->sqlUpdate ("article","ref_statut = '3'","id_article = '$id_article'");		
			}
			$mydb->sqlDelete("commande","id_commande = $id_commande");		
			$mydb->sqlDelete("commande_article","ref_commande = $id_commande");
			$session->param("commandid","");
			}		
	} else {
		print "Content-Type: text/html\n\n";
		print "trouble clearing caddie<br/>";
	}
}

sub getToDeliverCounter {
    my $call = shift || '';
    my $username = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $depot = $query->param("depot");
    
    
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  ($c)= $mydb->sqlSelectMany("distinct id_a_livre",
			   "article,a_livre,personne",
			   "ref_article = id_article AND ref_vendeur = id_personne  AND nom_utilisateur = '$username' and a_livre.ref_statut = '9' and ref_condition_livraison <> 8 and ref_condition_livraison <> 9");	
	
	while( ($ARTICLE{'nom_utilisateur'},$ARTICLE{'question'},$ARTICLE{'texte'},$ARTICLE{'date'})=$c->fetchrow()) {
	    $total +=1;
	}        
return $total;    
		
}

sub getDeliverWaitingCounter {
    my $call = shift || '';
    my $username = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $depot = $query->param("depot");
    
    
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  ($c)= $mydb->sqlSelectMany("distinct id_a_livre",
			   "article,a_livre,personne",
			   "ref_article = id_article AND ref_acheteur = id_personne  AND nom_utilisateur = '$username' and (a_livre.ref_statut = '9' or a_livre.ref_statut = '14') and ref_condition_livraison <> 8 and ref_condition_livraison <> 9");	
	
	while( ($ARTICLE{'nom_utilisateur'},$ARTICLE{'question'},$ARTICLE{'texte'},$ARTICLE{'date'})=$c->fetchrow()) {
	    $total +=1;
	}        
	return $total;    	
}
sub getToEffectedCounter {
    my $call = shift || '';
    my $username = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $depot = $query->param("depot");    
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  ($c)= $mydb->sqlSelectMany("distinct id_article",
			   "article,a_livre,personne,met_en_vente",
			   "a_livre.ref_article = id_article AND met_en_vente.ref_article = article.id_article and met_en_vente.ref_vendeur = id_personne  AND nom_utilisateur = '$username' and a_livre.ref_statut = '16'");	
	
	while( ($ARTICLE{'nom_utilisateur'},$ARTICLE{'question'},$ARTICLE{'texte'},$ARTICLE{'date'})=$c->fetchrow()) {
	    $total +=1;
	}        
return $total;   
		
}

sub getSoulevementAllerChercherCounter {
	my $call = shift || '';   
    my $username = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $depot = $query->param("depot");
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  ($c)= $mydb->sqlSelect("count(id_article)",
			   "article,a_livre,personne",
			   "ref_article = id_article AND ref_acheteur = id_personne  AND nom_utilisateur = '$username' and a_livre.ref_statut = '9' and ref_condition_livraison = 9");	
return $c;    
	
}
sub getSoulevementCounter {
    my $call = shift || '';   
    my $username = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $depot = $query->param("depot");
    
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  ($c)= $mydb->sqlSelect("count(id_article)",
			   "article,a_livre,personne",
			   "ref_article = id_article AND ref_vendeur = id_personne  AND nom_utilisateur = '$username' and a_livre.ref_statut = '9' and ref_condition_livraison = 9");	
return $c;    
		
}
sub getBuyWaitingCounter {

    my $article = $query->param("article");
    my $call = shift || '';
    my $username = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $depot = $query->param("depot");
    
    
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  ($c)= $mydb->sqlSelectMany("id_article",
			   "article,met_en_vente,personne,a_paye",
			   "met_en_vente.ref_article = id_article AND met_en_vente.ref_vendeur = id_personne AND nom_utilisateur = '$username' and (a_paye.ref_statut = '13' or a_paye.ref_statut = '8') AND a_paye.ref_vendeur = id_personne AND a_paye.ref_article = id_article");	
	
	while( ($ARTICLE{'nom_utilisateur'},$ARTICLE{'question'},$ARTICLE{'texte'},$ARTICLE{'date'})=$c->fetchrow()) {
	    $total +=1;
	}        
return $total;    
	
}

sub loadCounterMyBuyToBuy {
    my $call = shift || '';
    my $username = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $depot = $query->param("depot");
    
    
    my  $string = "";
    my  $index = '0';                                                                                               
    my  $total = '0';
    my  ($c)= $mydb->sqlSelectMany("id_article",
			   "article,personne,a_paye",
			   "a_paye.ref_article = id_article AND a_paye.ref_acheteur = id_personne AND nom_utilisateur = '$username' and a_paye.ref_statut = '8' AND a_paye.ref_acheteur = id_personne");	
	
	while( ($ARTICLE{'nom_utilisateur'},$ARTICLE{'question'},$ARTICLE{'texte'},$ARTICLE{'date'})=$c->fetchrow()) {
	    $total +=1;
	}        
return $total;    

}
sub getInvenduCounter {

    my $article = $query->param("article");
    my $call = shift || '';
    my $username = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $depot = $query->param("depot");
    
    
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  ($c)= $mydb->sqlSelectMany("id_article",
			   "article,met_en_vente,personne",
			   "ref_article = id_article AND ref_vendeur = id_personne AND nom_utilisateur = '$username' and article.ref_statut = '11'");	
	
	while( ($ARTICLE{'nom_utilisateur'},$ARTICLE{'question'},$ARTICLE{'texte'},$ARTICLE{'date'})=$c->fetchrow()) {
	    $total +=1;
	}        
return $total;    
	
}

sub RC4 {
 my($message,$key) = @_;
 my($RC4);
 my(@asciiary);
 my(@keyary);
 my($index,$jump,$temp,$y,$t,$x,$keylen);
 $keylen = length($key);
 for ($index = 0; $index <= 255; $index++) {
  $keyary[$index] = ord(substr($key, ($index%$keylen) + 1, 1));
 }
 for ($index = 0; $index <= 255; $index++) {$asciiary[$index] = $index;}
 $jump = 0;
 for ($index = 0; $index <= 255; $index++) {
  $jump = ($jump + $asciiary[$index] + $keyary[$index])%256;
  $temp = $asciiary[$index];
  $asciiary[$index] = $asciiary[$jump];
  $asciiary[$jump] = $temp;
 }
 $index = 0;
 $jump = 0;
 for ($x = 0; $x < length($message); $x++) {
  $index = ($index + 1)%256;
  $jump = ($jump + $asciiary[$index])%256;
  $t = ($asciiary[$index] + $asciiary[$jump])%256;
  $temp = $asciiary[$index];
  $asciiary[$index] = $asciiary[$jump];
  $asciiary[$jump] = $temp;
  $y = $asciiary[$t];
  $RC4 .= chr(ord(substr($message, $x, 1))^$y);
 }
 return($RC4);
}

sub string2hex {
 my($instring) = @_;
 my($retval,$strlen,$posx,$tval,$h1,$h2);
 my(@hexvals) = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
 $strlen = length($instring);
 for ($posx = 0; $posx < $strlen; $posx++) {
  $tval = ord(substr($instring,$posx,1));
  $h1 = int($tval/16);
  $h2 = int($tval - ($h1*16));
  $retval .= $hexvals[$h1] . $hexvals[$h2];
 }
 return($retval);
}

sub hex2string {
 my($instring) = @_;
 my($retval,$strlen,$posx);
 $strlen = length($instring);
 for ($posx = 0; $posx < $strlen; $posx=$posx+2) {
  $retval .= chr(hex(substr($instring,$posx,2)));
 }
 return($retval);
}

sub getMyCurrentDealCounter {
    $lang = $query->param("lang");
    loadLanguage();
    my $u = $query->param("u");
    my $param1 = shift || '';
    #my $decrypted =  &RC4(&hex2string($u),$the_key);
    my $article = $query->param("article");
    my $username = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $depot = $query->param("depot");
    
    
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  ($c)= $mydb->sqlSelectMany("id_article",
			   "article,met_en_vente,personne",
			   "ref_article = id_article AND ref_vendeur = id_personne AND nom_utilisateur = '$username' and article.ref_statut = '3'");	
	
	while( ($ARTICLE{'nom_utilisateur'},$ARTICLE{'question'},$ARTICLE{'texte'},$ARTICLE{'date'})=$c->fetchrow()) {
	    $total +=1;
	}        
return $total;    
	
}

sub getMyCurrentBuyCounter {
    my $call = shift || '';
    my $u = $query->param("u");
    my $decrypted =  shift || '';
    my $article = $query->param("article");
    my $username = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $depot = $query->param("depot");
    
    
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  ($c)= $mydb->sqlSelectMany("id_article",
			   "article,a_livre,personne",
			   "ref_article = id_article AND ref_acheteur = id_personne AND nom_utilisateur = '$decrypted' and a_livre.ref_statut = '16'");	
	
	while( ($ARTICLE{'nom_utilisateur'},$ARTICLE{'question'},$ARTICLE{'texte'},$ARTICLE{'date'})=$c->fetchrow()) {
	    $total +=1;
	}        
return $total;    
	
}


sub addOtherArticle {
	
	my  $category = $query->param("category");
	my  $name = $query->param("name");
	my  $country = $query->param("country");
	my  $fabricant = $query->param("fabricant") ;
	my  $description = $query->param("editor1");
	$description =~ s/'/'''/g;
	my  $price = $query->param("price");
	my $lang = $query->param("lang");
	my  $subcat = $query->param("subcat");
	my $km = $query->param("km");if (!$km) { $km = 0;}
	my $nb_cylindre = $query->param("nb_cylindre");if (!$nb_cylindre) {$nb_cylindre = 0;}
	my $horse = $query->param("horse");if (!$horse){$horse = 0;}
	my $year_fabrication = $query->param("year_fabrication");	
	if (!$year_fabrication) {$year_fabrication = '0000';}
	my $year_service = $query->param("year_service");
	if (!$year_service) { $year_service = '0000-00-00 00:00:00';}
	my $type_essence = $query->param("type_essence");
	my $year2 = $query->param ("year");
	my $condition_payement = $query->param("condition_payement");
	my $condition_livraison = $query->param("condition_livraison");
	my $canton = $query->param("departement");
	my $departement = $query->param("departement");
	my $city = $query->param("city");
	my $adress = $query->param("adress");
	my $nbr_piece = $query->param("nbr_piece");if (!$nbr_piece) { $nbr_piece = 0;}
	my $habitable_surface = $query->param("habitable_surface");
	my $terrain_surface = $query->param("terrain_surface");
	my $date_construction = $query->param("date_construction");
	if (!$habitable_surface) {$habitable_surface = '0.00';}
	my $is_location_or_buy = $query->param("is_location_or_buy");	
	my  $session = new CGI::Session( "driver:File", $session_id,  {Directory=>"$session_dir"} ); 
	my  $user  = $query->param("u");
	my $cookie_in = $query->cookie("USERNAME");
	my $decrypted =  &RC4(&hex2string($cookie_in),$the_key);
	my $level = $session->param("level");
	my $option_main_page = $query->param("option_main_page");
	my $option_main_cat = $query->param("option_main_cat");
	my $option_pack_photo = $query->param("option_pack_photo");
	my $type_ecran = $query->param("type_ecran");
	my $is_enchere = $query->param("is_enchere");
	my $enchere_date_start = $query->param("enchere_date_start");
	if (!$enchere_date_start) { $enchere_date_start = '0000-00-00 00:00:00';}	
	my $enchere_date_end= $query->param("enchere_end_day");
	if (!$enchere_date_end) { $enchere_date_end = '0000-00-00 00:00:00';}	
	my $dimension = $query->param("dimension");my $enchere;
	my $processor = $query->param("processor");
	if (!$processor) { $processor = '0.00';}
	my $ram = $query->param("ram");
	my $hard_driver = $query->param("hard_drive");
	my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
	my  $date = sprintf "%4d-%02d-%02d",$year+1900,$mon+1,$mday;
	my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
	my $speed_box = $query->param("speed_box");
	my $with_clima = $query->param("with_clima");
	my $with_cima_value;my $speed_box_value;
	my $provenance = $query->param ("wine_country");
	my $quantity = $query->param("quantity");
	my $id_provenance;
	my $longueur = $query->param("longueur");	
	if (!$longueur) { $longueur = 0;}
	my $largeur = $query->param("largeur");
	if (!$largeur) { $largeur = 0;}
	my $conso = $query->param("conso");
	if (! $conso) {$conso = 0;}    
	my $acteurs   = $query->param("actor");
	my $duree =  $query->param("duration");
	my $realisateur  = $query->param("realisator");
	my $game_type = $query->param("game_type");
        my $region = $query->param("wine_country");
	my $cepage = $query->param("cepage");
        my $wine_type = $query->param("wine_type");
        my $autor = $query->param("autor");
        my $size = $query->param("size");
	my $code_postal = $query->param("code_postal");
        my $used = $query->param("used");
	my $error = 0;
	if ($name eq "") {
	    $ERROR{'name_value_required'} = $ERROR{'name_value_required'};
	    $error = "1";
	}
	
	if ($name eq "") {
	    $ERROR{'name_value_required'} = $ERROR{'name_value_required'};
	    $error = "1";
	}
	if ($error eq "1") {
	    loadAddArticle();
	    return 1;
	}else { 	
        # ajouter italien
	if ($is_enchere eq "Yes" or ($is_enchere eq "Oui") or ($is_enchere eq "Ya")) {	$enchere = 1;}
	else {
	    $enchere = 0;
	if ($quantity eq "") {
	    $ERROR{'name_value_required'} = "coucou";
	    $error = 1;
	}

            # reformater si date américaine
	    ;my $dt = DateTime->last_day_of_month( year => $year+1900, month => $mon+1 );
	    while ( $dt->day_of_week >= 6 ) {
		$dt->subtract( days => 1 )
		}
	    $enchere_date_end =  $dt->ymd ." $time ";}
	if ($with_clima) {
            if ($with_clima eq 'Yes' or $with_clima eq 'Oui' or $with_clima eq 'Ya') {
                $with_cima_value = 1;
            }else {
                $with_cima_value = 0;
                }
            }else {
                $with_cima_value = 0;
            }
	my $id_region;my $id_wine_country;my $essence_or_diesel;my $used_or_new;
	if ($type_essence) {                                                                                   
	    ($essence_or_diesel)=$mydb->sqlSelect("ref_type_essence", " type_essence, type_essence_libelle_langue, libelle", "libelle = '$type_essence' AND type_essence_libelle_langue.ref_libelle = libelle.id_libelle");}else { $essence_or_diesel = 0;}
	my $id_country;
	if ($country) {
	    $id_country = $mydb->sqlSelect("id_pays_present", " pays_present", "nom = '$country'");
	}
        else {$id_country = '0';}
	if ($used) {($used_or_new)=$mydb->sqlSelect("ref_etat", " etat_libelle_langue,libelle,langue", "libelle.libelle = '$used' AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' AND libelle.id_libelle = etat_libelle_langue.ref_libelle");}else {$used_or_new = 2; }
	if ($provenance) {($id_provenance)=$mydb->sqlSelect("id_pays_present", "pays_present", "nom = '$provenance'");
	    }else {$id_provenance = 0;}
	if (!$ram) { $ram = 0;}
	if ($region) {($id_region)=$mydb->sqlSelect("id_pays_region_vin","pays_region_vin,pays_present","ref_pays = id_pays_present AND pays_present.nom = '$provenance' AND pays_region_vin.nom= '$region' ");} else {$id_region = 0;}
	
	
	my $id_cepage;my $id_type_de_vin;
        if ($cepage) {($id_cepage) = $mydb->sqlSelect("id_cepage","pays_region_vin,cepage","ref_pays_region_vin = id_pays_region_vin AND pays_region_vin.nom = '$region' AND cepage.nom= '$cepage'");}else {$id_cepage = 0;}
    	
	my  ($subcatID);
        if ($wine_type) {
	$id_type_de_vin = $mydb->sqlSelect("ref_type_de_vin","type_de_vin_libelle_langue, libelle, langue",
				    "type_de_vin_libelle_langue.ref_libelle = libelle.id_libelle AND  libelle.libelle = '$wine_type' AND type_de_vin_libelle_langue.ref_libelle = libelle.id_libelle AND type_de_vin_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
			  $subcatID = '0';
	}else {$id_type_de_vin = 0;

}
	
        my $id_departement;
	if ($speed_box) {($speed_box_value)=$mydb->sqlSelect("ref_boite_de_vitesse", "boite_de_vitesse_libelle_langue, libelle", "libelle.libelle= '$speed_box' AND boite_de_vitesse_libelle_langue.ref_libelle = libelle.id_libelle");}else { $speed_box_value = 0;}	
	if ($departement) {($id_departement)=$mydb->sqlSelect("id_departement", "departement", "nom = '$departement'");} else {$id_departement = 0;}
	if ($level eq '2') {$LINK{'admin'} = "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&amp;page=cms_manage_article;\" class=\"menulink\" >Admin</a>";}
	else {$LINK{'admin'} = "";}
	#if ($username) {
		my  ($userID)=$mydb->sqlSelect("id_personne", "personne", "nom_utilisateur = '$decrypted'");

		my ($ref_genre);
		my  $categorie_id = getCategoryID($category);

		my ($game_typeID);
                if ($categorie_id eq '6' or $categorie_id eq '7') {($subcatID)=$mydb->sqlSelect("ref_subcategorie", "subcategorie, subcategorie_libelle_langue, libelle, langue", "libelle.libelle = '$subcat' and subcategorie_libelle_langue.ref_categorie = '$categorie_id' AND  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'") if ($subcatID eq '');}else {($subcatID)=$mydb->sqlSelect("ref_subcategorie", "subcategorie_libelle_langue, libelle, langue", "libelle.libelle = '$subcat' AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'") if ($subcatID eq '');}
		my $type_ecran_id;
                if ($type_ecran) {($type_ecran_id)=$mydb->sqlSelect("id_type_ecran", "type_ecran, type_ecran_libelle_langue, libelle", "libelle.libelle = '$type_ecran' AND type_ecran.id_type_ecran = type_ecran_libelle_langue.ref_type_ecran AND type_ecran_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' AND libelle.id_libelle = type_ecran_libelle_langue.ref_libelle");
							     }else {$type_ecran_id = 0;}
		if ($game_type) {($game_typeID)=$mydb->sqlSelect("id_type_de_jeux", "type_de_jeux, type_de_jeux_libelle_langue, libelle", "libelle.libelle = '$game_type' AND type_de_jeux.id_type_de_jeux = type_de_jeux_libelle_langue.ref_type_de_jeux AND type_de_jeux.ref_libelle = libelle.id_libelle");}
		else {$game_typeID = '0';}
		my ($condition_payement_ref)  = $mydb->sqlSelect("ref_condition_payement", "condition_payement_libelle_langue, libelle, langue", "libelle.libelle= '$condition_payement' AND condition_payement_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' AND condition_payement_libelle_langue.ref_libelle = libelle.id_libelle");
		my ($condition_livraison_ref) = $mydb->sqlSelect("ref_condition_livraison", "condition_livraison_libelle_langue, libelle, langue", "libelle.libelle = '$condition_livraison'  AND condition_livraison_libelle_langue.ref_libelle = libelle.id_libelle AND condition_livraison_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
		my ($ref_canton);
		
		if ($canton)
		{($ref_canton) = $mydb->sqlSelect("id_canton", "canton_$lang", "nom = '$canton'");
		    
		    }else {
		    $ref_canton = 0;
													 }
		my ($is_location_or_buy_ref);
		print "is location or buy $is_location_or_buy";
		if ($is_location_or_buy) {(
					   $is_location_or_buy_ref) = $mydb->sqlSelect1("ref_location_ou_achat", "location_ou_achat_libelle_langue, libelle, langue", "libelle.libelle= '$is_location_or_buy' AND location_ou_achat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' AND location_ou_achat_libelle_langue.ref_libelle = libelle.id_libelle");
					
		    }else {$is_location_or_buy_ref = 0;
																																					  }
		if (!$quantity) {$quantity = 1;	}
		if ($autor eq '') {
		    $autor = $fabricant;
	    
		}
		my  $file = $query->param('image');

		my $fileSize = -s $file;
		if ($fileSize > 1024) {
		    $ERROR{'name_value_required'} = "Le fichier est trop grand";
		    loadAddArticle();
		    return 1;
		}else {		
		
		$mydb->sqlInsert("article",
			    marque 		=> "$fabricant",
			    nom			=> "$name",
			    auteur		=> "$autor",
			    ref_type_de_jeux    => "$game_typeID",
			    label		=> "$description",
			    nb_km		=> "$km",
			    prix		=> "$price",
			    nb_cheveaux 	=> "$horse",
			    lang		=> "$lang",
			    ref_condition_payement => "$condition_payement_ref",
			    ref_condition_livraison => "$condition_livraison_ref",
			    ref_subcategorie 	=> "$subcatID",
			    pochette		=> "",
			    presound		=> "",
			    ref_genre		=> "0",
			    taille		=> "$size",
			    nb_cylindre		=> "$nb_cylindre",
			    etat		=> '0',
			    essence_ou_diesel => "$essence_or_diesel",
			    ref_location_ou_achat => "$is_location_or_buy_ref",
			    ref_categorie	=> "$categorie_id",
			    owned		=> '0',
			    lieu		=> "$city",
			    adresse		=> "$adress",
			    nb_piece 		=> "$nbr_piece",
			    surface_habitable 	=> "$habitable_surface",
			    superficie_terrain 	=> "$terrain_surface",
			    premiere_immatriculation => "$year_service",
			    annee 		  => "$year_fabrication",
			    ref_statut		  => '3',
			    ref_pays		  => "$id_country",
			    ref_type_ecran        => "$type_ecran_id",
			    ref_canton		  => "$ref_canton",
			    date		  => "$date $time",
			    enchere	  	  => "$enchere",
			    enchere_date_debut    => "$enchere_date_start",
			    enchere_date_fin      => "$enchere_date_end",
			    processeur		  => "$processor",
			    ram 		  => "$ram",
			    ref_departement       => "$id_departement",
			    ref_boite_de_vitesse  => "$speed_box_value",
			    clima                 => "$with_cima_value",
			    ref_provenance      => "$id_provenance",
			    quantite		=> "$quantity",
			    longueur		=> "$longueur",
			    largeur		=> "$largeur",
			    consomation		=> "$conso",
			    acteurs		=> "$acteurs",
			    npa                 => "$code_postal",
			    duree		=> "$duree",
			    realisateur		=> "$realisateur",
			    annee		=> "$year",
			    ref_cepage          => "$id_cepage",
			    ref_type_de_vin     => "$id_type_de_vin",
			    annee_construction    => "$date_construction",
			    ref_pays_region_vin => "$id_region",
			    ref_etat		=> "$used_or_new",
			    disque_dur	        => $hard_driver
		   );
		my  @d = $mydb->sqlSelect("id_article", "article","date='$date $time'");
		my  $ref_article = $d[0];
		
		$mydb->sqlInsert("met_en_vente",
			ref_vendeur		=> "$userID",
			ref_article		=> "$ref_article",
			date_stock		=> "$date",
			page_principale 	=> "on",
			page_categorie 		=> "on",
			notre_selection 	=> '1',
			pack_photo		=> "$option_pack_photo"
		);
		#alertUserAVinyWishIsArrived();
		$imageManinpulation->uploadImage($ref_article);
		my  $url = "../upload/$ref_article/thumb.".$ref_article.".png";
		$mydb->sqlUpdate("article", "id_article = $ref_article",(pochette => $url));
         	print "Location: https:/$host/cgi-bin/recordz.cgi?page=main&lang=$lang&session=$session_id&u=$u\n\n";
		loadMainPage();
	}
	}
}

sub loadAddArticleTEST {
    our $lp = LoadProperties->create();
    open (FILE, "<$dir/add_other2.html");
    my $content ="" ;
	my $cats = getCat();
    while (<FILE>) {	
        s/\$ERROR{'([\w]+)'}/ exists $ERROR{$1} ? $ERROR{$1} : $1 /eg; 
        s/\$LANG/$lang/g;
        s/\$ERROR{'([\w]+)'}/ exists $ERROR{$1} ? $ERROR{$1} : $1 /eg; 
		$content .= $_;	
    }
    print "Content-Type: text/html\n\n"; 
    print $content;
    close (FILE);    	
}
sub loadAddArticle {
    #our $lp = LoadProperties->create();
    loadError();
    loadLanguage();
    my $maincat = $query->param("category");
    my $subcat = $query->param("subcat");
    my $entities = '&amp;';
    $subcat =~ s/[&]/$entities/ge;			      
    my $load = $query->param("isencher");
    my $name =$query->param("name");
    my $article =$query->param("article");;
    my $country = $query->param("country");
    my $lieu;
    my $categoriesTosearch = $lp->loadCategories();
    my $departement = $query->param("departement");
    my $u = $query->param("u");
    my $dimension ;
    my $level = 2;#$session->param("level");
    	my $error = 0;
	my $title = "";
	my $description_value = "";
	if ($name eq "") {
	    $title = $LABEL{'name_value_required'};
	    $error = "1";
	} else {
	    $title = "";
	}
	
	if ($description eq "") {
	    $description_value = $LABEL{'description_value_required'};
	} else {
	    $description_value = "";
	}

    if ($level eq '2') {$LINK{'admin'} = "<a href=\"javascript:void(0)\" class=\"menulink\"  onclick=\"window.open('/cgi-bin/recordz.cgi?lang=$lang&amp;page=cms_manage_article&amp;session=$session_id;','MyWindow','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=no,width=800,height=600,left=20,top=20')\">Admin</a>";      }
    else {$LINK{'admin'} = ""; }
    #if ($username) {
	#my  $dir = "C:/indigoperl/apache/htdocs/recordz/";
	my  $string = $lp->getCategoryGo ();
	my $menu = loadMenu();
	my  $string4;
	my $type_ecran;
	my $payement;
	my $livraison;
	my $informatique_properties;
	my $properties;
	my $fabricant;
	my $isenchere;
	my $carp ;
	my $quantity;
	my $location_or_buy;
	my $location_place;
	if ($maincat) {
	    $string4 = $lp->loadSubCategoriesOther();
	    $string4 =~ s/[&]/$entities/ge;			      
	    }
	my $res = $query->param("isencher");
	if ($res eq 'yes' or $res eq 'Yes' or $res eq 'oui' or $res eq 'Oui' or $res eq 'ya' or $res eq 'Ya') {
		$properties = $lp->loadEnchereProperties();
	}
	$isenchere = $lp->getIsEnchere();
	my  ($subcatID)=$mydb->sqlSelect("ref_subcategorie", "subcategorie_libelle_langue, langue, libelle", "libelle.libelle = '$subcat' AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
	my  ($catID)=$mydb->sqlSelect("ref_categorie", "categorie_libelle_langue,  langue, libelle", "libelle.libelle = '$maincat' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
	my $wine_country;
	
	if ($subcatID eq '12') {
		$type_ecran = $lp->loadTypeEcran();
		$dimension = $lp->loadTvDimension();
	}
	if ($catID ne '21' and $catID ne '25' and $catID ne '9'  and $catID ne '38') {		
		$fabricant = $lp->loadFabricant();

	}
	if ($catID eq '9') {
	    $fabricant = $lp->loadEditor();
	}
	
	if ($catID eq '25') {
	    $location_or_buy = $lp->loadIsBuyOrLocation();
	    $location_place = $lp->loadCityLocation();
	    #code
	}
	
	$payement = getConditionPayement();
	$livraison = getConditionLivraison();
	my $wine_region;
	my $cepage;
	my $wine_type;
	my $autor;
	my $year_fabrication;
	if ($catID eq '9') {$autor = $lp->loadAutor();}
	if ($catID eq '27') {
		#pays		
		$wine_country = $lp->loadAddWineCountry();
		$string4= "";
		$wine_region = $lp->loadAddWineRegion();
		$cepage = $lp->loadAddWineCepage();
		$wine_type = $lp->loadAddWineType();
		$year_fabrication = $lp->loadWineYear();
	}
	my $used;
	if ($load eq "Non" || $load eq "No" || $load eq "Nein" || $load eq "Ni") {
	  $quantity = $lp->loadQuantity();
	}
	
	if ($catID ne '5') {		
		$used = $lp->loadUsedOrNew();
	}
	
	if ($catID eq '5' or $catID eq '6') {
		$carp = $lp->getCarProperties();
		$used = $lp->loadUsedOrNew();
	}
	my $game_type;
	if ($catID eq '29') {
	    $game_type = $lp->loadAddGamesType();
	}
	
	if ($subcatID eq '75' or $subcatID eq '78'  or $subcatID eq '79'  or $subcatID eq '80') {
	    $informatique_properties = $lp->loadInfoPcProperties();}
	my $dvd_properties;
	if ($catID eq '38') {
	    $dvd_properties = $lp->loadDvdProperties();
	}
	my $offshore_properties;
	if ($catID eq '94') {
	    $offshore_properties = $lp->loadOffshoreProperties();}
	my $size;
	if ($subcatID eq '311' or $subcatID eq '1' or $subcatID eq '2' or $subcatID eq '3' or $subcatID eq '4' or $subcatID eq '6' or $subcatID eq '28' or $subcatID eq '29' or $subcatID eq '30' or $subcatID eq '32') {
	    $size = $lp->loadWearSize($ARTICLE{'size'});
	}
	my $content = "" ;
	my $cats = getCat();

	open (FILE, "<$dir/add_other2.html") or die "cannot open file $dir/add_other2.html";    	
	while (<FILE>) {	
	    s/\$ERROR{'([\w]+)'}/ exists $ERROR{$1} ? $ERROR{$1} : $1 /eg; 
	    s/\$LANG/$lang/g;
	    s/\$ERROR{'name_value_required'}/$title/g;
	    s/\$ERROR{'description_value_required'}/$description_value/g;
	    s/\$ARTICLE{'main_menu'}/$menu/g;
	    s/\$SELECT{'condition_payement'}/$payement/g;
	    s/\$SELECT{'condition_livraison'}/$livraison/g;
	    s/\$ARTICLE{'informatique_properties'}/$informatique_properties/g;
	    s/\$SELECT{'isenchere'}/$isenchere/g;
	    s/\$SELECT{'offshore_properties'}/$offshore_properties/g;
	    s/\$SELECT{'type_ecran'}/$type_ecran/g;
	    s/\$LINK{'admin'}/$LINK{'admin'}/g;
	    s/\$OPTIONS{'categories'}/$cats/g;
	    s/\$ARTICLE{'dvd_properties'}/$dvd_properties/g;
	    s/\$SELECT{'wine_country'}/$wine_country/g;
	    s/\$SELECT{'cepage'}/$cepage/g;
	    s/\$ARTICLE{'year_fabrication'}/$year_fabrication/g;
	    s/\$SELECT{'used'}/$used/g;
	    s/\$SELECT{'location_place'}/$location_place/g;
	    s/\$SELECT{'lieu'}/$lieu/g;
	    s/\$SELECT{'auto_properties'}/$carp/g;
	    s/\$SELECT{'dimension'}/$dimension/g;
	    s/\$ARTICLE{'name'}/$name/g;
	    s/\$ARTICLE{'autor'}/$autor/g;
	    s/\$ARTICLE{'size'}/$size/g;
	    s/\$SELECT{'game_type'}/$game_type/g;
	    s/\$SELECT{'quantity'}/$quantity/g;
	    s/\$SELECT{'enchere_fabricant'}/$fabricant/g;
		s/\$SESSIONID/$session_id/g;
	    s/\$ARTICLE{'description'}/$description/g;
	    s/\$ARTICLE{'price'}/$price/;
	    s/\$SELECT{'location_or_buy'}/$location_or_buy/g;
	    s/\$SELECT{'wine_region'}/$wine_region/g;
	    s/\$SELECT{'wine_type'}/$wine_type/g;
	    s/\$u/$u/g;
		s/\$OPTIONS{'category'}/$string/g;
	    s/\$SELECT{'subcat'}/$string4/g;
	    #s/\$SELECT{'dimension'}/g;
		s/\$SELECT{'enchere_properties'}/$properties/g;
	    $content .= $_;	
        } 	
	print "Content-Type: text/html\n\n";
	print $content;	
    close (FILE);
    }
 
sub loadCategories {
    my $string;
    my %OPTIONS = ();
    my  ($c)= $mydb->sqlSelectMany("libelle.libelle","categorie_libelle_langue,libelle, langue","categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");	
    while(($OPTIONS{'category'})=$c->fetchrow()) {	
         $string .= "<option value=\"$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";
    }#

    return $string;
}

sub loadMenu {
	my $string = "";
	loadLanguage ();
	my $country_swiss = $query->param("country_swiss");my $country_france = $query->param("country_france");
	my $with_lang_french = $query->param("with_lang_french");my $with_lang_german = $query->param("with_lang_german");
	my $with_lang_italian = $query->param("with_lang_italian");my $with_lang_english = $query->param("with_lang_english");
	my $u = $query->param("u");
	#$string .=  "<li><img src=\"../images/charity.gif\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=charity&amp;session=$session_id&amp;country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=$with_lang_french&amp;with_lang_italian=$with_lang_italian&amp;with_lang_german=$with_lang_german&amp;with_lang_english=$with_lang_english\" class=\"menulink\" >$SERVER{'charity'}</a><img src=\"../images/charity.gif\"></li>";
	$string .=  "<li><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=art_design\" class=\"menulink\" >$SERVER{'art'}</a></li>";
	$string .=  "<li><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=parfum\" class=\"menulink\" >$SERVER{'parfum_cosmetik'}</a></li>";
	$string .=  "<li><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=wear_news\" class=\"menulink\" >$SERVER{'fashion'}</a></li>";
	$string .=  "<li><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=lingerie\" class=\"menulink\" >$SERVER{'lingerie'}</a></li>";
	$string .=  "<li><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=baby\" class=\"menulink\" >$SERVER{'baby'}</a></li>";
	$string .=  "<li><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=animal\" class=\"menulink\" >$SERVER{'animal'}</a></li>";
	$string .=  "<li><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=watch\" class=\"menulink\" >$SERVER{'watch_jewels'}</a></li>";
	$string .=  "<li><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=jardin\" class=\"menulink\" >$SERVER{'Habitat_et_jardin'}</a></li>";	
	$string .=  "<li><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=auto\" class=\"menulink\" >$SERVER{'car'}</a></li>";
	$string .=  "<li><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=moto\" class=\"menulink\" >$SERVER{'moto'}</a></li>";	
	$string .=  "<li><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=immo\" class=\"menulink\" >$SERVER{'real_estate'}</a></li>";
	$string .=  "<li><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=cd_vinyl_mixtap\" class=\"menulink\" >$SERVER{'cd_music'}</a></li>";
	$string .=  "<li><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=intruments\" class=\"menulink\" >$SERVER{'music_instrument'}</a></li>";	
	#$string .=  "<li><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=cigares&amp;session=$session_id&amp;country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=$with_lang_french&amp;with_lang_italian=$with_lang_italian&amp;with_lang_german=$with_lang_german&amp;with_lang_english=$with_lang_english\" class=\"menulink\" >$SERVER{'cigares'}</a></li>";
	$string .=  "<li><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=collection\" class=\"menulink\" >$SERVER{'collections'}</a></li>";
	#$string .=  "<li><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=caviar&amp;session=$session_id&amp;country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=$with_lang_french&amp;with_lang_italian=$with_lang_italian&amp;with_lang_german=$with_lang_german&amp;with_lang_english=$with_lang_english\" class=\"menulink\" >$SERVER{'caviar'}</a></li>";	
	$string .=  "<li><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=wine\" class=\"menulink\" >$SERVER{'wine'}</a></li>";
	$string .=  "<li><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=boat\" class=\"menulink\" >$SERVER{'boat'}</a></li>";		
	$string .=  "<li><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=tv_video\" class=\"menulink\" >$SERVER{'tv_video_camera'}</a></li>";	
	#$string .=  "<li><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=informatique&u=$u&amp;session=$session_id&amp;country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=$with_lang_french&amp;with_lang_italian=$with_lang_italian&amp;with_lang_german=$with_lang_german&amp;with_lang_english=$with_lang_english;\" class=\"menulink\" >$SERVER{'computer_it'}</a></li>";
	$string .=  "<li><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=games\" class=\"menulink\" >$SERVER{'games'}</a></li>";
	$string .=  "<li><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=book\" class=\"menulink\" >$SERVER{'book'}</a></li>";	
	$string .=  "<li><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=dvd\" class=\"menulink\" >$SERVER{'dvd_k7'}</a></li>";	
	$string .=  "<li><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=sport\" class=\"menulink\" >$SERVER{'sport'}</a></li>";
	return $string;
}

sub loadMainPage {
    my $content = "";
    my $type_p = $query->param("saw");    
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my ($y, $m, $d, $hh, $mm, $ss) = (localtime)[5,4,3,2,1,0]; $y += 1900; $m++;
    my $string1;
    my $string2;
    if ($m < 10) {
	 $m = "0$m";
    }
    	$string1 = loadArticleSelection();;
	    $string2 = viewArticleSelectionByIndex();;

    my $iso_now = "$y-$m-$d";
    my $dt = DateTime->last_day_of_month( year => $year+1900, month => $mon+1 );
	    while ( $dt->day_of_week >= 6 ) {
		$dt->subtract( days => 1 )
		}
	    $enchere_date_end =  $dt->ymd;
   	my %OPTIONS = ();
    my $enchere_duration_rest =  timeDiff("$iso_now + 30","$enchere_date_end"); 
	my ($c) = $mydb->sqlSelectMany("pochette,nom,id_article","article","pub = 1 AND pub_date_start <= '$iso_now' AND pub_date_end >= '$iso_now' ORDER BY Rand() LIMIT 0,4");
	my $i = 0;
	while( ($ARTICLE{'image_url'},$ARTICLE{'nom'},$ARTICLE{'id_article'})=$c->fetchrow()) {
	    $ARTICLE{'image_pub'}.= "<img src='$ARTICLE{'image_url'}'</img>&nbsp;&nbsp;<a href=\"$host/cgi-bin/detail.pl?lang=$lang&action=detailother&article=$ARTICLE{'id_article'}\"</a>$ARTICLE{'nom'}&nbsp;&nbsp;";	    
	    $i += 1;
	}

	my $categories = loadCategories();
	my $menu = loadMenu();
	
    open (FILE, "<$dir/main.html") or die "cannot open file $dir/main.html";

    while (<FILE>) {
	    s/\$ERROR{'([\w]+)'}/ exists $ERROR{$1} ? $ERROR{$1} : $1 /eg; 
	    s/\$LANG/$lang/g;
	    s/\$ERROR{'([\w]+)'}/ exists $ERROR{$1} ? $ERROR{$1} : $1 /eg; 
	    s/\$OPTIONS{'categories'}/$categories/g;
	    s/\$ARTICLE{'main_menu'}/$menu/g;
	    
	    s/\$ARTICLE{'names'}/$ARTICLE{'names'}/g;
	    s/\$ARTICLE{'best_offers_index'}/$string1/g;
	    s/\$ARTICLE{'best_offers_table'}/$string2/g;
	    s/\$u/$u/g;
	    s/\$LINK{'add_deal'}/$LINK{'add_deal'}/g;
	    s/\$SESSIONID/$session_id/g;

	$content .= $_;	
    }
    print $content;
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
	my $ss1    = substr($date1,17, 2) if (length($date1) > 16);
		 #$ss1  ||= 0;

	my $year2  = substr($date2, 0, 4);
	my $month2 = substr($date2, 5, 2);
	my $day2   = substr($date2, 8, 2);
	my $hh2    = substr($date2,11, 2) || 0;
	my $mm2    = substr($date2,14, 2) || 0;
	my $ss2    = substr($date2,17, 2) if (length($date2) > 16);
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



sub getCategoryID {
    my  $category = shift || '';   
    my  ($c)= $mydb->sqlSelectMany("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");	
    my  $string = "";my  %OPTIONS = ();
    while(($OPTIONS{'category'})=$c->fetchrow()) {$string .= "$OPTIONS{'category'}";}
    return $string;    
}

sub getImmoProperties {
     
    my $call = shift || '';
    my $string = "";
    my $nb_piece = shift || '';
    my $surface_habitable = shift || '';
    
    my $superficie_terrain = shift || '';
    my $annee_construction  = shift || '';
    my $ref_canton = shift || '';
    my $lieu = shift || '';
    my $adresse = shift || '';
    my $npa = shift || '';
    my $ref_location_ou_achat = shift || '';
    my $ref_departement = shift || '';
    
    ($ARTICLE{'canton'}) = $mydb->sqlSelect("nom","canton_fr","id_canton = $ref_canton");
    $string .=  "<tr><td>$SERVER{'nb_piece'}</td><td><input type=\"text\" name =\"nb_piece\" value=\"$nb_piece\"</input></td></tr>";
    $string .=  "<tr><td>$SERVER{'surface_habitable'}</td><td><input type=\"text\" name =\"surface_habitable\" value=\"$surface_habitable\"</input></td></tr>";
    $string .=  "<tr><td>$SERVER{'superficie_terrain'}</td><td><input type=\"text\" name =\"superficie_terrain\" value=\"$superficie_terrain\"</input></td></tr>";    
    $string .=  "<tr><td>$SERVER{'construction_date'}</td><td><input type=\"text\" name =\"annee_construction\" value=\"$annee_construction\"</input></td></tr>";    
    $string .=  "<tr><td>$SERVER{'canton'}</td><td><input type=\"text\" name =\"ref_canton\" value=\"$ARTICLE{'canton'}\"</input></td></tr>";    
    $string .=  "<tr><td>$SERVER{'lieu'}</td><td><input type=\"text\" name =\"lieu\" value=\"$lieu\"</input></td></tr>";    
    $string .=  "<tr><td>$SERVER{'adresse'}</td><td><input type=\"text\" name =\"adresse\" value=\"$adresse\"</input></td></tr>";    
    $string .=  "<tr><td>$SERVER{'npa'}</td><td><input type=\"text\" name =\"npa\" value=\"$npa\"</input></td></tr>";    
    
    ($ARTICLE{'location_ou_achat_selected_libelle'}) =  $mydb->sqlSelect ("libelle.libelle","libelle, langue, location_ou_achat_libelle_langue"," location_ou_achat_libelle_langue.ref_location_ou_achat = '$ref_location_ou_achat' AND location_ou_achat_libelle_langue.ref_libelle = libelle.id_libelle");
    $string .= "<tr><td>$SERVER{'location_ou_achat'}</td><td><input type=\"text\  name=\"location_ou_achat\" value=\"$ARTICLE{'location_ou_achat_selected_libelle'}\"</input></td></tr>";

    
    return $string;    
    
}

sub updateArticleStatut {
    	my $username = $query->param("u");
	my $decrypted =  &RC4(&hex2string($username),$the_key);
	my $encrypt =  &string2hex(&RC4($decypted,$the_key));
	my $article = $query->param("article");
	my $id_a_livre = $query->param("id_a_livre");
	my $buyer = $query->param("buyer");
	my $commentaire = $query->param("commentaire");
	my $note = $query->param("note");
	print "Content-Type: text/html\n\n";
	print "id_a_livre : $id_a_livre\n";
	if ($username) {
		my  ($userID)=sqlSelect("id_personne", "personne", "nom_utilisateur = '$username'");		
		my  ($isenchere)=sqlSelect("enchere", "article", "id_article = '$isenchere'");
		if ($isenchere eq '1') {
				($ARTICLE{'max_enchere'})=sqlSelect("MAX(prix)", "enchere", "ref_article = '$article'");						
				($ARTICLE{'ref_enchereur'},$ARTICLE{'id_enchere'})=sqlSelect("ref_enchereur,id_enchere", "enchere", "ref_article = '$article' AND prix = '$ARTICLE{'max_enchere'}'");    							
		}else {
			$ARTICLE{'ref_enchereur'} = sqlSelect("id_personne", "personne", "nom_utilisateur = '$buyer'");		
		}
		my  ($articleUserID)=sqlSelect("id_personne", "personne,article,met_en_vente", "met_en_vente.ref_article  = id_article AND id_article = $article AND ref_vendeur = id_personne");

		if ($userID eq $articleUserID) {
				my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
				my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
				my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
			#	sqlUpdate("article", "id_article=$article",(ref_statut => "14"));
				sqlUpdate("a_livre", "id_a_livre=$id_a_livre",(ref_statut => "14"));
				($ARTICLE{'email'})=sqlSelect("email", "personne", "id_personne = $ARTICLE{'ref_enchereur'}");									        
				# article livré

				#article livré mail
			    my  $Message = new MIME::Lite From =>'robot@djmarketplace.biz',
					To =>$ARTICLE{'email'}, Subject =>$SERVER{'article_deliver'} ,
					Type =>'TEXT',
					Data =>"$SERVER{'article_deliver'}";       
					$Message->attr("content-type" => "text/html; charset=iso-8859-1");
					$Message->send_by_smtp('localhost:25');


			loadMyEnchereDeal();	
		}
		else {
			#modification d'un article d'un autre user
		}
	}
}

sub updateArticleStatutWaitingBuy {
	my $call = shift || '';
	my $article = $query->param("article");
	my $buyer = $query->param("buyer");
	my $commentaire = $query->param("commentaire");
	my $note = $query->param("note");
	my $u = $query->param("u");
	my $cookie_in = $query->cookie("USERNAME"); 
	my $decrypted =  &RC4(&hex2string($cookie_in),$the_key);
	my $udec = &RC4(&hex2string($u),$the_key);
	if($decrypted eq $u)  {
	my $username = $decrypted;
	my $id_a_paye = $query->param("id_a_paye");
	
	if ($username) {
		my  ($userID)=$mydb->sqlSelect("id_personne", "personne", "nom_utilisateur = '$username'");
		my  ($isenchere,$condition_livraison)=$mydb->sqlSelect("enchere,ref_condition_livraison", "article", "id_article = '$article'");

		my  ($vendeurID)=$mydb->sqlSelect("id_personne", "personne,met_en_vente,article", "ref_article = id_article AND id_article = '$article' AND ref_vendeur = id_personne");		

		if ($isenchere eq '1') {
			($ARTICLE{'max_enchere'})=$mydb->sqlSelect("MAX(prix)", "enchere", "ref_article = '$article'");						
			($ARTICLE{'ref_enchereur'},$ARTICLE{'id_enchere'})=$mydb->sqlSelect("ref_enchereur,id_enchere", "enchere", "ref_article = '$article' AND prix = '$ARTICLE{'max_enchere'}'");    				
		}else {
			my ($acheteur) = $mydb->sqlSelect("id_personne", "personne", "nom_utilisateur = '$buyer'");
			$ARTICLE{'ref_enchereur'} = $acheteur;
		}
		($ARTICLE{'email'})=$mydb->sqlSelect("email", "personne,met_en_vente", "ref_article = '$article' AND id_personne = ref_vendeur");
		($ARTICLE{'quantity'},$ARTICLE{'montant'})=$mydb->sqlSelect("quantite,montant", "a_paye", "id_a_paye = $id_a_paye");
		if ($userID eq $vendeurID) {
		    
				my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
				my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
				$date = trimwhitespace($date);				
				my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
				$time = trimwhitespace($time);
				#sqlUpdate("article", "id_article=$article",(ref_statut => "7"));
				$mydb->sqlUpdate("a_paye", "ref_article=$article AND ref_acheteur = '$ARTICLE{'ref_enchereur'}' AND id_a_paye = $id_a_paye",(ref_statut => "7"));

				$mydb->sqlUpdate("a_paye", "ref_article=$article AND ref_acheteur = '$ARTICLE{'ref_enchereur'}' AND id_a_paye = $id_a_paye",(date_payement => "$date $time"));

				$mydb->sqlInsert("a_livre",
						ref_article	 => "$article",
						ref_vendeur  => $vendeurID,
						ref_acheteur => $ARTICLE{'ref_enchereur'},
						#ref_enchere  => $ARTICLE{'id_enchere'},
						date_achat   => "$date $time",
						quantite      => "$ARTICLE{'quantity'}",
						montant 	=> "$ARTICLE{'montant'}",
						ref_mode_livraison => "$condition_livraison",
						ref_statut => "9"
				);

				$mydb->sqlInsert("evaluation_achat",

				      ref_article   => "$article",
				      ref_vendeur   => "$userID",
				      ref_acheteur  => "$ARTICLE{'ref_enchereur'}",
				      note	    => "$note",
				      commentaire   => "$commentaire",
				      date  	    => "$date $time"
				  );
			loadMyEnchereDeal($option);
			#print header(-Refresh => "5;url=https:/avant-garde.no-ip.biz/cgi-bin/recordz.cgi?lang=$lang&page=myencheredeal&session=$session&option=mybuywaiting&u=;");

    	}
	}
	} else {
			print "Content-type: text/html\n";
			print "error";
		}

}
sub updateArticleStatutWaitingBuy2 {
    
    
	my $call = shift || '';
	my $article = $query->param("article");
	my $buyer = $query->param("buyer");
	my $commentaire = $query->param("commentaire");
	my $note = $query->param("note");
	my $u = $query->param("u");
	my $cookie_in = $query->cookie("USERNAME"); 
	my $decrypted =  &RC4(&hex2string($cookie_in),$the_key);
	my $udec = &RC4(&hex2string($u),$the_key);
	if($decrypted eq $udec)  {
	print "Content-Type: text/html\n\n";
        print "test ok";





	
	
	my $username = $decrypted;
	my $id_a_paye = $query->param("id_a_paye");
	
	if ($username) {
	    print "username $username";
		my  ($userID)=$mydb->sqlSelect("id_personne", "personne", "nom_utilisateur = '$username'");
		my  ($isenchere,$condition_livraison)=$mydb->sqlSelect("enchere,ref_condition_livraison", "article", "id_article = '$article'");

		my  ($vendeurID)=$mydb->sqlSelect("id_personne", "personne,met_en_vente,article", "ref_article = id_article AND id_article = '$article' AND ref_vendeur = id_personne");		

		if ($isenchere eq '1') {
			($ARTICLE{'max_enchere'})=$mydb->sqlSelect("MAX(prix)", "enchere", "ref_article = '$article'");						
			($ARTICLE{'ref_enchereur'},$ARTICLE{'id_enchere'})=$mydb->sqlSelect("ref_enchereur,id_enchere", "enchere", "ref_article = '$article' AND prix = '$ARTICLE{'max_enchere'}'");    				
		}else {
			my ($acheteur) = $mydb->sqlSelect("id_personne", "personne", "nom_utilisateur = '$buyer'");
			$ARTICLE{'ref_enchereur'} = $acheteur;
		}
		($ARTICLE{'email'})=$mydb->sqlSelect("email", "personne,met_en_vente", "ref_article = '$article' AND id_personne = ref_vendeur");
		($ARTICLE{'quantity'},$ARTICLE{'montant'})=$mydb->sqlSelect("quantite,montant", "a_paye", "id_a_paye = $id_a_paye");

		print "$userID - $vendeurID";
		if ($userID eq $vendeurID) {
		    
				my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
				my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
				$date = trimwhitespace($date);				
				my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
				$time = trimwhitespace($time);
				#sqlUpdate("article", "id_article=$article",(ref_statut => "7"));
				$mydb->sqlUpdate("a_paye", "ref_article=$article AND ref_acheteur = '$ARTICLE{'ref_enchereur'}' AND id_a_paye = $id_a_paye",(ref_statut => "7"));

				$mydb->sqlUpdate("a_paye", "ref_article=$article AND ref_acheteur = '$ARTICLE{'ref_enchereur'}' AND id_a_paye = $id_a_paye",(date_payement => "$date $time"));

				$mydb->sqlInsert("a_livre",
						ref_article	 => "$article",
						ref_vendeur  => $vendeurID,
						ref_acheteur => $ARTICLE{'ref_enchereur'},
						#ref_enchere  => $ARTICLE{'id_enchere'},
						date_achat   => "$date $time",
						quantite      => "$ARTICLE{'quantity'}",
						montant 	=> "$ARTICLE{'montant'}",
						ref_mode_livraison => "$condition_livraison",
						ref_statut => "9"
				);

				$mydb->sqlInsert("evaluation_achat",

				      ref_article   => "$article",
				      ref_vendeur   => "$userID",
				      ref_acheteur  => "$ARTICLE{'ref_enchereur'}",
				      note	    => "$note",
				      commentaire   => "$commentaire",
				      date  	    => "$date $time"
				  );
			#loadMyEnchereDeal($option);
			#print "Expires: 0\n"; # Expire immediately
			#print "Pragma: no-cache\n"; # Work as NPH
			#print "Content-type: text/html\n\n"; # <- mentioned as context
			print header(-Refresh => "5;url=$host/cgi-bin/recordz.cgi?lang=$lang&page=myencheredeal&session=$session&option=mybuywaiting&u=;");

    	}
	}
	} else {
			print "Content-type: text/html\n";
			print "error";
		}

}

sub loadMyEnchereDeal {
	my $call = shift || '';
	my $menu = loadMenu();
	my $article = shift || '' ;
	my $option = $query->param("option");
	my  $session = new CGI::Session( "driver:File", $session_id,  {Directory=>"$session_dir"} );
	my $username = $query->param("u");
	
	my $encrypt =  &string2hex(&RC4($decypted,$the_key));
	$cookie_in = $query->cookie("USERNAME"); 
	my $decrypted =  &RC4(&hex2string($cookie_in),$the_key);
	if($decrypted) { 
	    my $table_index_invendu;
	    my $table_invendu;
	    my $cats = getCat();
	    my $invendu_counter = getInvenduCounter ($decrypted);
	    my $current_deal_counter = getMyCurrentDealCounter($decrypted);	
	    my $buy_waiting_counter = getBuyWaitingCounter($decrypted);
	    my $buy_current = getMyCurrentBuyCounter();
	    my $table_index_todeliver;
	    my $table_todeliver;
	    my $todeliver_counter = getToDeliverCounter ($decrypted);
	    my $effected_counter = getToEffectedCounter($decrypted);
	    my $soulevement_counter = getSoulevementCounter($decrypted);
	    my $deliver_waiting_counter = getDeliverWaitingCounter($decrypted);
	    my $table_index_current_deal;
	    my $table_current_deal;
	    my $table_buy_waiting;
	    my $table_index_buy_waiting;
	    my $table_effect;
	    my $table_index_effect;
	    my $table_index_soulevement;
	    my $table_soulevement;
	    my $counterMyBuyToBuy;
	    my $tableCounterMyBuyToBuy;
	    my $tableIndexCounterMyBuyToBuy;
	    my $tableIndexWaitDelivering;
	    my $tableWaitDelivering;
	    my $tableBuyIndex;
	    my $tableBuy;
	    my $deal_passed_index;
	    my $deal_passed_table;
	    my %IMG = ();
	    my %SELECT = ();
	    my $type_article = $query->param("category");
	    my $brand = $query->param("brand");
	    $counterMyBuyToBuy = loadCounterMyBuyToBuy($decrypted);
	    if ($option eq 'mynotdeal') {
		    $table_index_invendu = $tableArticle->loadTableIndexInvendu($decrypted);
		    $table_invendu= $tableArticle->loadTableByIndexInvendu($decrypted);
							     
	    }elsif ($option eq 'mybuytodeliver') {
		    $table_index_todeliver = $tableArticle->loadTableIndexToDeliver($decrypted);
		    $table_todeliver = $tableArticle->loadTableByIndexToDeliver($decrypted);
	    }elsif ($option eq 'mybuysoulevement') {
		    $table_index_soulevement = $tableArticle->loadTableIndexSoulevement($decrypted);
		    $table_soulevement = $tableArticle->loadTableByIndexSoulevement($decrypted);
    
	    }elsif ($option eq 'mycurrentdeal') {
		    $table_index_current_deal = $tableArticle->loadTableIndexCurrentDeal($decrypted);
		    $table_current_deal = $tableArticle->loadTableByIndexCurrentDeal($decrypted);
	    }elsif ($option eq 'mybuywaiting') {
		    $table_index_buy_waiting = $tableArticle->loadTableIndexMyBuyWaiting($decrypted);
		    $table_buy_waiting = $tableArticle->loadTableByIndexMyBuyWaiting($decrypted);
	    }elsif ($option eq 'mybuyeffect') {
		    $table_effect = $tableArticle->loadTableByIndexEffect ($decrypted);
		    $table_index_effect =  $tableArticle->loadIndexEffect ($decrypted);
	    }elsif ($option eq 'mybuytobuy') {		
		    $tableIndexCounterMyBuyToBuy = $tableArticle->loadCounterMyBuyTable($decrypted);
		    $tableCounterMyBuyToBuy = $tableArticle->loadMyBuyToBuyTable($decrypted);
	    }elsif ($option eq 'mywaitdelivering') {
		    $tableIndexWaitDelivering = $tableArticle->loadIndexWaitDeliver($decrypted);
		    $tableWaitDelivering = $tableArticle->loadTableWaitDeliver($decrypted);
	    }elsif ($option eq 'mycurrentbuy') {
		    $tableBuyIndex = $articleClass->loadTableIndexMyBuy($decrypted);
		    $tableBuy = $articleClass->loadTableByIndexMyBuy($decrypted);		    
	    }elsif ($option eq "mydealpassed") {
		    $deal_passed_index = $articleClass->showMyDealPassedIndex($decrypted);
		    $deal_passed_table = $articleClass->showMyDealPassedTable($decrypted);
    	    
	    }elsif ($option eq 'statdealarticlebrand') {
		    my ($c) = $mydb->sqlSelectMany("libelle.libelle","categorie_libelle_langue,libelle,langue", "categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue  = langue.id_langue AND langue.key = '$lang'");
		    $SELECT{'type_article'} = "<td>$SERVER{'type_article'}</td><td><select name=\"category\" onchange=\"go();\">";
		    my  %OPTIONS = ();
		    my $selected = $query->param("category");
		    $SELECT{'type_article'} .= "<option selected VALUE=\"$selected\">$selected</option>";
		    while(($OPTIONS{'category'})=$c->fetchrow()) {	
		         $SELECT{'type_article'} .= "<option value=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=myencheredeal&session=$session_id&option=statdealarticlebrand&u=$username&category=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";
		    }
		    $SELECT{'type_article'} .= "</select></td>";
		    ($c) = $db->sqlSelectMany("DISTINCT article.marque","article,personne,categorie_libelle_langue, met_en_vente", "personne.nom_utilisateur = '$decrypted' and met_en_vente.ref_vendeur = personne.id_personne AND met_en_vente.ref_article = article.id_article AND article.ref_categorie = (SELECT ref_categorie FROM categorie_libelle_langue,libelle,langue WHERE libelle.libelle = '$selected' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle and categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')");
		    %OPTIONS = ();
		    my $category = $query->param("category");
		    #my $selected = $query->param("brand");
		    $SELECT{'brand'} = "<td>$SERVER{'type_article'}</td><td><select name=\"brand\" onchange=\"go2();\">";
		    $SELECT{'brand'} .= "<option selected VALUE=\"$selected\">$selected</option>";
		    while(($OPTIONS{'category'})=$c->fetchrow()) {	
		         $SELECT{'brand'} .= "<option value=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=myencheredeal&sesasion=$session_id&option=statdealarticlebrand&u=$username&category=$category&brand=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";
		    }
		    $SELECT{'brand'} .= "</select>";
		     
		    $IMG{'statistiques_brand'} = $imageManipulation->generateGraphicStatArticleBrand($brand, $decrypted);
	    } elsif ($option eq 'statdealarticleville') {
		    my ($c) = $mydb->sqlSelectMany("nom","canton_fr", "id_canton = id_canton");
		    $SELECT{'canton'} .= "<td>$SERVER{'type_article'}</td><td><select name=\"canton\" onchange=\"go3();\">";
		    my  %OPTIONS = ();
		    my $selected = $query->param("canton");
		    $SELECT{'canton'} .= "<option selected VALUE=\"$selected\">$selected</option>";
		    while(($OPTIONS{'category'})=$c->fetchrow()) {	
		         $SELECT{'canton'} .= "<option value=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=myencheredeal&session=$session_id&option=statdealarticleville&u=$username&canton=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";
		    }
		$SELECT{'canton'} .= "</select>";
		if ($selected) {
		    $IMG{'statistiques_canton'} = $imageManipulation->generateGraphicStatArticleCanton($selected, $decrypted);
		}
		
		
	    }
	    my ($counter_deal_passed) = $mydb->sqlSelect("count(*)","article,met_en_vente,a_paye,personne", "met_en_vente.ref_article = id_article and met_en_vente.ref_vendeur = id_personne and nom_utilisateur = '$decrypted' and a_paye.ref_article = id_article and a_paye.ref_statut = '7'");

	    my $categoriesTosearch = loadCategories();
	    open (FILE, "<$dir/myencheredeal.html") or die "cannot open file $dir/myencheredeal.html";
	    my $content;
	    while (<FILE>) {	
		s/\$LABEL'([\w]+)'}/ exists $LABEL{$1} ? $LABEL{$1} : $1 /eg; 
		s/\$LANG/$lang/g;
		s/\$ARTICLE{'current_deal_counter'}/$current_deal_counter/g;
		s/\$ARTICLE{'buy_waiting_counter'}/$buy_waiting_counter/g;
		s/\$LINK{'add_deal'}/$LINK{'add_deal'}/g;		
		s/\$ERROR{'([\w]+)'}/ exists $ERROR{$1} ? $ERROR{$1} : $1 /eg; 
		s/\$ARTICLE{'id_article'}/$article/g;
		s/\$ARTICLE{'soulevement_counter'}/$soulevement_counter/g;
		s/\$ARTICLE{'mybuyeffect_counter'}/$effected_counter/g;
		s/\$ARTICLE{'table_index_current_deal'}/$table_index_current_deal/g;
		s/\$ARTICLE{'table_current_deal'}/$table_current_deal/g;
		s/\$ARTICLE{'table_index_buywaiting'}/$table_index_buy_waiting/g;
		s/\$ARTICLE{'table_buywaiting'}/$table_buy_waiting/g;
		s/\$OPTIONS{'categories'}/$cats/g;
		s/\$ARTICLE{'invendu_counter'}/$invendu_counter/g;
		s/\$ARTICLE{'main_menu'}/$menu/g;
		s/\$ARTICLE{'table_index_deliver_waiting'}/$tableIndexWaitDelivering/g;;
		s/\$ARTICLE{'table_deliver_waiting'}/$tableWaitDelivering/g;
		s/\$ARTICLE{'todeliver_counter'}/$todeliver_counter/g;
		s/\$ARTICLE{'table_index_todeliver'}/$table_index_todeliver/g;
		s/\$ARTICLE{'mydeal_passed_index'}/$deal_passed_index/g;
		s/\$ARTICLE{'mydeal_passed_table'}/$deal_passed_table/g;
		s/\$ARTICLE{'table_todeliver'}/$table_todeliver/g;
		s/\$ARTICLE{'table_index_effect'}/$table_index_effect/g;
		s/\$ARTICLE{'table_effect'}/$table_effect/g;
		s/\$ARTICLE{'table_index_soulevement'}/$table_index_soulevement/g;
		s/\$ARTICLE{'table_soulevement'}/$table_soulevement/g;	    
		s/\$LINK{'admin'}/$LINK{'admin'}/g;
		s/\$ARTICLE{'deliver_counter'}/$deliver_waiting_counter/g;
		s/\$ARTICLE{'table_index_invendu'}/$table_index_invendu/g;
		s/\$ARTICLE{'table_invendu'}/$table_invendu/g;
		s/\$ARTICLE{'buy_counter'}/$counterMyBuyToBuy/g;
		
		s/\$OPTIONS{'categories'}/$categoriesTosearch/g;
		s/\$ARTICLE{'mybuytobuyindex'}/$tableIndexCounterMyBuyToBuy/g;
	        s/\$ARTICLE{'mybuytobuytable'}/$tableCounterMyBuyToBuy/g;
		s/\$ARTICLE{'current_buy_counter'}/$buy_current/g;
		s/\$u/$username/g;
		s/\$ARTICLE{'my_deal_passed_counter'}/$counter_deal_passed/g;
		s/\$ARTICLE{'mybuyindex'}/$tableBuyIndex/g;
		s/\$ARTICLE{'mybuy_table'}/$tableBuy/g;
		s/\$SELECT{'type_article'}/$SELECT{'type_article'}/g;
		s/\$SELECT{'brand'}/$SELECT{'brand'}/g;
		s/\$SELECT{'canton'}/$SELECT{'canton'}/g;
		s/\$IMG{'statistiques_brand'}/$IMG{'statistiques_brand'}/g;
		s/\$IMG{'statistiques_canton'}/$IMG{'statistiques_canton'}/g;
		s/\$SESSIONID/$session_id/g;
		$content .= $_;	
	    }
	

	    print "Content-Type: text/html\n\n"; 
	    print $content;
	    close (FILE);
	}
}

sub trimwhitespace($) {
  my $string = shift || '';
  $string =~ s/^\s+//;
  $string =~ s/\s+$//;
  return $string;
}

sub loadTableIndexMyBuy {
    my $u = $query->param("u");
    my $decrypted =  &RC4(&hex2string($u),$the_key);
    my $article = $query->param("article");
    my $call = shift || '';
    my $username = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $depot = $query->param("depot");
    
    
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  ($c)= $mydb->sqlSelectMany("distinct id_article",
			   "article,a_livre,personne",
			   "a_livre.ref_article = id_article AND a_livre.ref_acheteur = id_personne  AND nom_utilisateur = '$username' and a_livre.ref_statut= '16' AND a_livre.ref_acheteur = id_personne AND a_livre.ref_article = id_article");	
	
	while( ($ARTICLE{'nom_utilisateur'},$ARTICLE{'question'},$ARTICLE{'texte'},$ARTICLE{'date'})=$c->fetchrow()) {
	    $total +=1;
	}

    my  $nb_page = arrondi ($total / 4, 1);
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
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&page=myencheredeal&option=mycurrentdeal&amp;min_index=$min_index&amp;max_index=$max_index\"  class=\"menulink2\" ><-$j-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }
        
return $string;    
}


sub loadTableByIndexMyBuy {
    loadLanguage();
    my $u = $query->param("u");
    my $decrypted =  &RC4(&hex2string($u),$the_key);
    my $call = shift || '';
    my $username = shift || '';
    my  $index_start = $query->param ("min_index");
    my  $index_end = $query->param ("max_index");
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);

    my  $string = "";
    my  $add;
    my  $add2;
    my  $dep;
    
    if (!$index_start ) {
	$index_start = 0;
    }
    if (!$index_end ) {
	$index_end = 40;
    }

    my $string = "<table style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><tr style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"151\">$SERVER{'article_name_label'}</td><td align=\"left\">$SERVER{'fabricant'}</a></td><td align=\"left\">$SERVER{'article_price_label'}</td><td align=\"left\">$SERVER{'quantity'}</td><</tr>";;
    my  ($c)= $mydb->sqlSelectMany("DISTINCT a_livre.ref_acheteur,pochette,article.nom,id_article,id_a_livre,a_livre.quantite,a_livre.montant,marque",
			   "article,personne,a_livre,met_en_vente",
			   "a_livre.ref_article = id_article AND a_livre.ref_acheteur = id_personne  AND nom_utilisateur = '$username' and a_livre.ref_statut = '16' AND a_livre.ref_acheteur = id_personne AND a_livre.ref_article = id_article LIMIT $index_start, $index_end");	
    

    my $i = 0;
    my $j = 0;
    
    
    while( ($ARTICLE{'ref_acheteur'},$ARTICLE{'pochette'},$ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'id_a_paye'},$ARTICLE{'quantity'},$ARTICLE{'montant'},$ARTICLE{'fabricant'})=$c->fetchrow()) {
	my  ($achteur)=$mydb->sqlSelect("nom_utilisateur", "personne", "id_personne = '$ARTICLE{'ref_acheteur'}'");	
	#$string .= " <label>&nbsp;&nbsp;$ARTICLE{'genre'}</label>";
	$string .= "<tr><td align=\"left\"><img alt=\"\" src=\"$ARTICLE{'pochette'}\" alt=\"\"/></td><td align=\"left\"><a href=\"/cgi-bin/detail.pl?lang=$lang&amp;session=$session_id&amp;action=detailother&amp;article=$ARTICLE{'id_article'}\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td>$ARTICLE{'fabricant'}</td><td align=\"left\">$ARTICLE{'montant'}</td><td align=\"left\">$ARTICLE{'quantity'}</td><td align=\"left\"></td></tr>";
    }
    $string .= "</table>";
    return $string;
        
}
sub showArticleIndex {

	my $strinng = "TEST";
	return $string;
}
sub showArticleIndexFinal {
    my $option = $query->param("enchere");
    my $dealer = $query->param("username");
    my $vendu = $query->param("vendu");
    my  $from = "article";
    my  $where;
    my $string;
    #doDealerIndex
    my  $total = '0';
    
    my  ($c)= $mydb->sqlSelectMany("distinct id_article",
			   "article,a_paye,personne",
			   "a_paye.ref_article = id_article AND a_paye.ref_acheteur = id_personne  AND nom_utilisateur = '$u' and a_paye.ref_statut = '7' AND a_paye.ref_acheteur = id_personne AND a_paye.ref_article = id_article");	
	
	while( ($ARTICLE{'nom_utilisateur'},$ARTICLE{'question'},$ARTICLE{'texte'},$ARTICLE{'date'})=$c->fetchrow()) {
	    $total +=1;
	}
    
	$min_index += 40;	
	my $string = "";
	my $first_page = 0;
	my $nb_page = 0;
	my $min_index = $query->param("min_index");
	if (not defined $min_index) {
		$min_index = 0;
	}
	my $count_per_page = 10;
	my $content = "";
	my $max_index = $query->param("max_index");	
	if (not defined $max_index) {		
		$max_index = 40;
	} else {
		#$max_index = round ($counter / 40, 1);#Number of objects displayed per page.
	}		
	my $last_page = $nb_page - 1;
	my $n2 = 0;

	my $index_page = $query->param("index_page");
	if (not defined $index_page) {
		$index_page = 0;
	}
	my $previous_page = $query->param("previous_page");	
	if (not defined $previous_page) {
		$index_page = 0;
		$previous_page = 0;
	}
	my $index = 0;
#	$string .= "<a href=\"/cgi-bin/pagination.pl?lang=FR&amp;session=1\" ><-\"First page\"-></a>&#160;&nbsp;";				
	$string .= "<a href=\"/cgi-bin/detail_dealer.pl?lang=$lang&amp;session=$session_id&page=profil_vendeur&username=$dealer&enchere=$option&min_index0&max_index=40&amp;previous_page=$previous_page&amp;index_page=$index_page\ class=\"menulink2\" >First page</a>&#160;&nbsp;";				
	my $counter = ($total / $count_per_page); #Should be get from db;
	
	if (($index_page -1) > 0) {
		$previous_page = $previous_page - 1;
		$index_page--;
		$index--;
		$min_index = $min_index -40;
		$max_index = $max_index -40;
		#$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&page=profil_vendeur&username=$dealer&enchere=$option&min_index=$min_index&max_index=$max_index\"  class=\"menulink2\" ><-$i-></a>&#160;&nbsp;";		
		$string .= "<a href=\"/cgi-bin/detail_dealer.pl?lang=$lang&amp;session=$session_id&page=profil_vendeur&username=$dealer&enchere=$option&min_index=$min_index&max_index=$max_index&amp;previous_page=$previous_page&amp;index_page=$index_page\ class=\"menulink2\" ><-\"$i\"-></a>&#160;&nbsp;";				
	}
	for my $index ($min_index..$counter) {						
		$next_page = $min_index + 40;
		if ($index_page < $count_per_page) {
			if (($index_page % $count_per_page) > 0) {							
				$string .= "<a href=\"/cgi-bin/detail_dealer.pl?lang=$lang&amp;session=$session_id&page=profil_vendeur&username=$dealer&enchere=$option&min_index=$min_index&max_index=$max_index&amp;previous_page=$previous_page&amp;index_page=$index_page\ class=\"menulink2\"  ><-$index_page-></a>&#160;&nbsp;";				
			}
		}		
		$index_page++;
		$index++;
		$counter--;
		$min_index += 40;;						
		$max_index += 40;;					
	}
	$string .= "<a href=\"/cgi-bin/detail_dealer.pl?lang=$lang&amp;session=$session_id&page=profil_vendeur&username=$dealer&enchere=$option&min_index=$min_index&max_index=$max_index&amp;previous_page=$previous_page&amp;index_page=$index_page\ class=\"menulink2\"  ><-Next\></a>&#160;&nbsp;";				
	return $content;
}


sub showArticleByIndex {
    my $u = $query->param("username");
    
    my $call = shift || '';
    my $username = shift || '';
    my  $index_start = $query->param ("min_index");
    	
    my  $index_end = $query->param ("max_index");
    
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);

    my  $string = "";
    my  $add;
    my  $add2;
    my  $dep;
    
    if (!$index_start ) {
	$index_start = 0;
    }
    if (!$index_end ) {
	$index_end = 40;
    }

    $string = "<table style=\"border-width:thin; border-style:dotted;border-top-color:#94CEFA;border-right-color:#94CEFA;border-left-color:#94CEFA;  border-bottom-color:#94CEFA\" width=\"555\" border=\"0\"><tr bgcolor=\"#DBE4F8\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"151\">$SERVER{'article_name_label'}</td><td align=\"left\">$SERVER{'buyer'}</td><td align=\"left\">$SERVER{'article_price_label'}</td><td align=\"left\">$SERVER{'article_quantity_buyed'}</td><td align=\"left\"></td></tr>";
    my  ($c)= $mydb->sqlSelectMany("DISTINCT a_paye.ref_acheteur,pochette,article.nom,id_article,id_a_paye,a_paye.quantite,a_paye.montant",
			   "article,personne,a_paye,met_en_vente",
			   "a_paye.ref_article = id_article AND a_paye.ref_acheteur = id_personne  AND nom_utilisateur = '$u' and a_paye.ref_statut = '7' AND a_paye.ref_acheteur = id_personne AND a_paye.ref_article = id_article LIMIT $index_start, $index_end");	
    

    my $i = 0;
    my $j = 0;
    
    my  $string = "<table style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><tr<td align=\"left\" width=\"51\"></td><td align=\"left\" width=\"151\"></td><td align=\"left\"></a></td><td align=\"left\"></td></tr>";
    while( ($ARTICLE{'ref_acheteur'},$ARTICLE{'pochette'},$ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'id_a_paye'},$ARTICLE{'quantity'},$ARTICLE{'montant'})=$c->fetchrow()) {
	my  ($achteur)=$mydb->sqlSelect("nom_utilisateur", "personne", "id_personne = '$ARTICLE{'ref_acheteur'}'");	
	#$string .= " <label>&nbsp;&nbsp;$ARTICLE{'genre'}</label>";
	$string .= "<tr><td align=\"left\"><img alt=\"\" src=\"$ARTICLE{'pochette'}\" alt=\"\"/></td><td align=\"left\"><a href=\"/cgi-bin/detail.pl?lang=$lang&amp;session=$session_id&amp;action=detailother&amp;article=$ARTICLE{'id_article'}\" class=\"menulink\" >$sARTICLE{'name'}</a></td><td align=\"left\">$achteur</td><td align=\"left\">$ARTICLE{'montant'}</td><td align=\"left\">$ARTICLE{'quantity'}</td><td align=\"left\"></td></tr>";
    }
    $string .= "</table>";
    return $string;
    
}


sub showMyDealPassedIndex {
    my $u = $query->param("u");
	my $lang = $query->param("lang");
    my $article = $query->param("article");
    my $decrypted =  &RC4(&hex2string($u),$the_key);
    my $call = shift || '';
    my $username = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $depot = $query->param("depot");
    
    
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  ($c)= $mydb->sqlSelectMany("distinct id_article",
			   "article,a_paye,personne",
			   "a_paye.ref_article = id_article AND a_paye.ref_vendeur = id_personne  AND nom_utilisateur = '$username' and a_paye.ref_statut = '7' AND a_paye.ref_vendeur = id_personne AND a_paye.ref_article = id_article");	
	
	while( ($ARTICLE{'nom_utilisateur'},$ARTICLE{'question'},$ARTICLE{'texte'},$ARTICLE{'date'})=$c->fetchrow()) {
	    $total +=1;
	}

    my  $nb_page = arrondi ($total / 4, 1);
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
	$string .= "<a href=\"/cgi-bin/my_auctions.pl?lang=$lang&amp;session=$session_id&page=myencheredeal&option=mycurrentdeal&option=mydealpassed&amp;min_index=$min_index&amp;max_index=$max_index\"  class=\"menulink2\" ><-$j-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }
        
return $string;    
    
}


sub showMyDealPassedTable {
    my $u = $query->param("u");
    my $decrypted =  &RC4(&hex2string($u),$the_key);
    my $call = shift || '';
    my $username = shift || '';
    my  $index_start = $query->param ("min_index");
    
    my  $index_end = $query->param ("max_index");
    
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);

    my  $string = "";
    my  $add;
    my  $add2;
    my  $dep;
    
    if (!$index_start ) {
	$index_start = 0;
    }
    if (!$index_end ) {
	$index_end = 40;
    }
	loadLanguage();
    my $string = "<table style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><tr style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"151\">$SERVER{'article_name_label'}</td><td align=\"left\">$SERVER{'fabricant'}</a></td><td align=\"left\">$SERVER{'article_price_label'}</td></tr>";;
    my  ($c)= $mydb->sqlSelectMany("a_paye.ref_acheteur,pochette,article.nom,id_article,id_a_paye,a_paye.montant",
			   "article,personne,a_paye,met_en_vente",
			   "met_en_vente.ref_article = id_article AND met_en_vente.ref_vendeur = id_personne  AND nom_utilisateur = '$username' and a_paye.ref_statut = '7' AND  a_paye.ref_article = id_article LIMIT $index_start, $index_end");	
    

    my $i = 0;
    my $j = 0;
    
    
    while( ($ARTICLE{'ref_acheteur'},$ARTICLE{'pochette'},$ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'id_a_paye'},$ARTICLE{'montant'})=$c->fetchrow()) {
	my  ($achteur)=$mydb->sqlSelect("nom_utilisateur", "personne", "id_personne = '$ARTICLE{'ref_acheteur'}'");	
	#$string .= " <label>&nbsp;&nbsp;$ARTICLE{'genre'}</label>";
	$string .= "<tr><td align=\"left\"><img alt=\"\" src=\"$ARTICLE{'pochette'}\" alt=\"\"/></td><td align=\"left\"><a href=\"/cgi-bin/detail.pl?lang=$lang&amp;session=$session_id&amp;action=detailother&amp;article=$ARTICLE{'id_article'}\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\"><a href=\"/cgi-bin/detail_dealer.pl?lang=$lang&amp;session=$session_id&amp;page=profil_vendeur&amp;username=$achteur\" class=\"menulink\" >$achteur</a></td><td align=\"left\">$ARTICLE{'montant'}</td><td align=\"left\"></td></tr>";
    }
    $string .= "</table>";
    return $string;
    
}

sub deleteItem {
    my $article = $query->param("article");
}
sub viewCommentIndex {
    my $lang = $query->param("lang");
    my $username = $query->param("username");
	my $min_index_comments = $query->param("min_index_comments");
	my $max_index_comments = $query->param("max_index_comments");
    my  ($c)= $mydb->sqlSelect("count(commentaire.id_commentaire)",
			   "commentaire,personne",
			   "commentaire.ref_emetteur = (SELECT id_personne FROM personne WHERE nom_utilisateur = '$username') AND personne.id_personne = commentaire.ref_emetteur");	
	

    my  $nb_page = arrondi ($c / 10, 1);
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
	$string .= "<a href=\"/cgi-bin/recordz.cgi?page=main&lang=$lang&amp;session=$session_id&amp;min_index_comments=$min_index&amp;max_index_comments=$max_index&amp;country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=$with_lang_french&amp;with_lang_german=$with_lang_german&amp;with_lang_italian=$with_lang_italian&amp;with_lang_english=$with_lang_english&saw=lasthour\"  class=\"menulink2\" ><-$j-></a>&#160;&nbsp;";		
	$min_index += 4;	
    }
    if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }        
return $string;    
    
}
sub viewCommentTable {
    my $lang = $query->param("lang");
    my $username = $query->param("username");
    my $min_index_comments = $query->param("min_index_comments");
    my $max_index_comments = $query->param("max_index_comments");
    my $article = $query->param("article");
    my  $cat = shift || '';
    my  $type = shift  || '';
    my  $depot = $query->param("depot") ;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
        my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $string = "";
    my  $add;
    my  $add2;
    my  $dep;    
    if (!$min_index_comments ) {
	$min_index_comments = 0;
    }
    if (!$max_index_comments ) {
	$max_index_comments = 40;
    }

    if ($cat) {
	$add = "AND genre.genre = '$cat'";
    } else {
	$add = "";
    }
    if ($type) {
	$add2 = "AND id_categorie = '$type'";
    } else {
	$add2 = "";		
    }

    if ($depot) {
	$dep = "AND ref_depot = (SELECT id_depot FROM depot WHERE ville = '$depot')";
    }

    my  ($c)= $mydb->sqlSelectMany("nom_utilisateur,question,texte,commentaire.date",
		        "commentaire, personne, article",
		       "ref_article = id_article and ref_emetteur = id_personne AND ref_emetteur = (SELECT (id_personne) FROM personne WHERE nom_utilisateur = '$username') LIMIT $min_index_comments, $max_index_comments");	
    

    my $i = 0;
    my $j = 0;
    $string = "<table style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><tr<td align=\"left\" width=\"51\"></td><td align=\"left\" width=\"151\"></td><td align=\"left\"></a></td><td align=\"left\"></td></tr>";
    $string .= "<tr>";
    while( ($ARTICLE{'nom_utilisateur'},$ARTICLE{'question'},$ARTICLE{'texte'},$ARTICLE{'date'})=$c->fetchrow()) {
	#$string .= " <label>&nbsp;&nbsp;$ARTICLE{'genre'}</label>";
	if ($ARTICLE{'pochette'} eq '') {
		$ARTICLE{'pochette'} = "../images/no.gif";
	}
	$ARTICLE{'label'} = substr($ARTICLE{'label'},0, 18);
	$ARTICLE{'label'} .= "...";
	$string .= "<td align=\"left\" width=\"300px\" style=\"border-style:dotted;border-width:thin;border-color:#94CEFA\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&amp;page=profil_vendeur&username=$ARTICLE{'nom_utilisateur'}\" class=\"menulink\" >$ARTICLE{'nom_utilisateur'}</a><br/>$ARTICLE{'question'}<br/>$ARTICLE{'texte'}<br/>$ARTICLE{'date'}</td>";
	$string .= "</tr>";
    }
    $string .= "</table>";
    return $string;
}

sub showVisiteursIndex {
    my $username = $query->param("username");
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  $add;
    my  $add2;
    my  $dep;
    my ($counter) = $mydb->sqlSelect("count(*)",
			   "visiteur,personne",
			   "personne.id_personne = visiteur.ref_personne and nom_utilisateur = '$username'");	
	
	my $first_page = 0;
	my $nb_page = 0;
	my $min_index = $query->param("min_index");
	if (not defined $min_index) {
		$min_index = 0;
	}
	my $count_per_page = 10;
	my $content = "";
	my $max_index = $query->param("max_index");	
	if (not defined $max_index) {		
		$max_index = 40;
	} else {
		#$max_index = round ($counter / 40, 1);#Number of objects displayed per page.
	}		
	my $last_page = $nb_page - 1;
	my $n2 = 0;

	my $index_page = $query->param("index_page");
	if (not defined $index_page) {
		$index_page = 0;
	}
	my $previous_page = $query->param("previous_page");	
	if (not defined $previous_page) {
		$index_page = 0;
		$previous_page = 0;
	}		
		$string .= "<a href=\"cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&amp;min_index=$min_index&amp;max_index=$max_index&amp;action=detailother&article=$article&viewcommentaire=1\"  class=\"menulink2\"amp;min_index_our_selection=$min_index&amp;max_index_our_selection=$max_index\" ><-\"First page\"-></a>&#160;&nbsp;";				
	
	if (($index_page -1) > 0) {
		$previous_page = $previous_page - 1;
		$index_page--;
		$index--;
		$min_index = $min_index -40;
		$max_index = $max_index -40;
#		$string .= "<a href=\"cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&amp;min_index=$min_index&amp;max_index=$max_index&amp;action=detailother&article=$article&viewcommentaire=1\"  class=\"menulink2\"amp;min_index_our_selection=$min_index&amp;max_index_our_selection=$max_index\" ><-\"First page\"-></a>&#160;&nbsp;";				
		$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=main&session=$session_id&amp;min_index_our_selection=$min_index&amp;max_index_our_selection=$max_index&amp;previous_page=$previous_page&amp;index_page=$index_page\" ><-\"Previous\"-></a>&#160;&nbsp;";				
	}
	for my $index ($min_index..$max_index) {						
		$next_page = $min_index + 40;
		if ($index_page < $count_per_page) {
			if (($index_page % $count_per_page) > 0) {							
				$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=main&session=$session_id&amp;min_index_our_selection=$min_index&amp;max_index_our_selection=$max_index&amp;previous_page=$previous_page&amp;index_page=$index_page\" ><-\"$index\"-></a>&#160;&nbsp;";				
			}
		}		
		$index_page++;
		$index++;
		$min_index += 40;;						
		$max_index += 40;;					
	}
		$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=main&session=$session_id&amp;min_index_our_selection=$min_index&amp;max_index_our_selection=$max_index&amp;previous_page=$previous_page&amp;index_page=$index_page\" ><-Next-></a>&#160;&nbsp;";	
		$min_index += 40;	
    	return $content;	
}        

sub showVisiteursTable {
    my $username = $query->param("username");    
    my  $index_start = $query->param ("min_index");
    my  $index_end = $query->param ("max_index");    
    my  $string = "";

    if (!$index_start ) {
		$index_start = 0;
    }
    if (!$index_end ) {
		$index_end = 40;
    }
	
    my  ($c)= $mydb->sqlSelectMany("nom_utilisateur",
		        "personne,visiteur",
		       " ref_visiteur =  personne.id_personne AND ref_personne = (SELECT DISTINCT(id_personne) FROM personne WHERE nom_utilisateur = '$username') LIMIT $index_start, $index_end");	
    

    my $i = 0;
    my $j = 0;
    $string .= "<table style=\"border-bottom:3px; border-left:3px; border-right:3px; border-top:3px;border-color:#94CEFA;\"><tr>";
    $string .= "<tr>";
    while( ($ARTICLE{'nom_utilisateur'})=$c->fetchrow()) {
	#$string .= " <label>&nbsp;&nbsp;$ARTICLE{'genre'}</label>";
	if ($ARTICLE{'pochette'} eq '') {
		$ARTICLE{'pochette'} = "../images/no.gif";
	}
	$ARTICLE{'label'} = substr($ARTICLE{'label'},0, 18);
	$ARTICLE{'label'} .= "...";
		$string .= "<td align=\"left\" width=\"300px\" style=\"border-style:border-color:#94CEFA\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&amp;page=profil_vendeur&username=$ARTICLE{'nom_utilisateur'}\" class=\"menulink\" >$ARTICLE{'nom_utilisateur'}</a></td>";
	$string .= "</tr>";
    }
    $string .= "</table>";
    return $string;
	
}
BEGIN {
    use Exporter ();  
    @Article::ISA = qw(Exporter);
    @Article::EXPORT      = qw(getCat addOtherArticle clearBasket loadCommentaireIndex viewCommentaireByIndex doDealerIndexed doDealerIndex getLastEnchereTable evalDealView getLastEnchereurDetail getLastEnchereurDetail getEnchereCounter loadMakeEnchere loadEnchereLastOffer getLinkPurchaseOther get_day_in_same_week getConditionPayement weekNews getArticleDetailCount  getArticleEnchereCount getConditionLivraison loadArticleSelection viewArticleSelectionByIndex getImagesForDetails   );
    @Article::EXPORT_OK   = qw();
} 

#END 1;
