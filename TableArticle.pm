package TableArticle;
use strict;

use SharedVariable qw ($action $session_dir $dir $dirLang $dirError $imgdir $session_id $can_do_gzip $current_ip $lang $LANG %ARTICLE %SESSION %SERVER %USER $CGISESSID %LABEL %ERROR %VALUE $COMMANDID %COMMAND %DATE %PAYPALL $INDEX %LINK  $query $session $host $t0  $client);  
use MyDB;

our $db = MyDB->new;
our $the_key = "otherbla";
sub new {
        my $class = shift;
        my ($opts)= @_;
	my $self = {};
	return bless $self, $class;
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



sub loadLastBuyersByIndex {
    my $article = $query->param("article");
    my  $index_start = $query->param ("min_index");
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index");
    $index_end =~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    
    if (!$index_start ) {$index_start = 0;}
    if (!$index_end ) {$index_end = 40;}
    my $string;
    my  ($c)= $db->sqlSelectMany("ref_acheteur,date_payement",
		       "article,a_paye",
		       "a_paye.ref_article = id_article  AND a_paye.ref_statut = '7' AND id_article = $article LIMIT $index_start, $index_end  ");	
    
    my $i = 0;my $j = 0;
    $string .= "<table style=\"border-top-width:medium;border-top-color:#94CEFA\">";    
    while( ($ARTICLE{'ref_acheteur'},$ARTICLE{'date_payement'})=$c->fetchrow()) {
	($ARTICLE{'username'})=sqlSelect("nom_utilisateur", "personne", "id_personne = $ARTICLE{'ref_acheteur'}");
	if ($ARTICLE{'pochette'} eq '') {$ARTICLE{'pochette'} = "../images/no.gif";}
	my $add3;
	if ($ARTICLE{'ref_categorie'} eq '11') {$add3 = $ARTICLE{'article_lieu'};}
	$string .= "<tr><td align=\"left\">$ARTICLE{'username'}</td><td align=\"left\">$ARTICLE{'date_payement'}</td></tr>";
	$i += 1;$j += 1;
	if ($i eq 1) {$string .= "<td align=\"left\" width=\"10px\"></td>";$i = 0;}	
	if ($j eq 2) {$string .= "</tr><tr></tr><tr></tr><tr>";$j = 0;}
    }    
    $string .= "</table>";
    return $string;
    
}

sub loadSportIndex {
    $lang = $query->param("lang") ;	    
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
    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");
    my  $add2;
    
    my $ref_cat;
    my $ref_subcat;
    if ($category) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $add .= " AND article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
    }
    if ($subcat) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcat' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $add .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
	
    if ($add eq "") {
	$add2 .= " AND article.ref_categorie  between 96 and 99 ";
    }	

    my  ($c)= $db->sqlSelect("count(id_article)",
			   "article,met_en_vente, categorie_libelle_langue $from",
			   "ref_article = id_article AND ref_statut = '3' AND  enchere_date_fin > '$date% ' AND quantite > 0 $add $add2");	
	
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
	$string .= "<a href=\"/cgi-bin/u.pl?lang=$lang&amp;page=sport&amp;session=$session_id&amp;min_index=$min_index&amp;max_index=$max_index&amp;country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=with_lang_french&amp;with_lang_italian=$with_lang_italian&amp;with_lang_german=with_lang_german&amp;with_lang_english=$with_lang_english\"   ><-$j-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }
    if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }
return $string;    

}

sub loadSportByIndex {
	loadLanguage();
    $lang = $query->param("lang") ;		
    my  $cat = shift || '';
    my  $type = shift  || '';
    my  $depot = $query->param("depot") ;
    $depot=~ s/[^A-Za-z0-9 ]//;
    my  $index_start = $query->param ("min_index");
    my $subcat = $query->param("subcat");
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index");
    $index_end =~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $string = "";
    my  $add;
    my $from;
    my $add2;
    my $category = $query->param("category");
    my $ref_cat;
    my $ref_subcat;
    if (!$index_start ) {$index_start = 0;}
    if (!$index_end ) {$index_end = 40;}
    if ($category) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $add .= " AND article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
    }
    if ($subcat) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcat' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $add .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
	
    if ($add eq "") {
	$add2 .= " AND article.ref_categorie between 96 and 99 ";
    }	
        my  ($c)= $db->sqlSelectMany("article.nom,id_article,marque,prix, categorie_libelle_langue.ref_categorie,pochette ",
		       "article,met_en_vente,categorie_libelle_langue, subcategorie_libelle_langue",
		       "ref_article = id_article  AND met_en_vente.notre_selection = '1'  AND ref_statut = '3' AND article.quantite > 0 and article.enchere_date_fin > '$date' AND categorie_libelle_langue.ref_categorie = article.ref_categorie AND subcategorie_libelle_langue.ref_subcategorie = article.ref_subcategorie $add  $add2 ORDER BY id_article DESC LIMIT $index_start, $index_end");	

    my $i = 0;my $j = 0;
    $string = "<table style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><tr style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"151\">$SERVER{'article_name_label'}</td><td align=\"left\">$SERVER{'fabricant'}</a></td><td align=\"left\">$SERVER{'article_price_label'}</td></tr>";
    
    while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'author'},$ARTICLE{'price'},$ARTICLE{'ref_categorie'},$ARTICLE{'image'})=$c->fetchrow()) {
	if ($ARTICLE{'image'} eq '') {
		##$ARTICLE{'image'} = "../images/blank.gif";
	}
        if ($ARTICLE{'ref_categorie'}) {
            $ARTICLE{'genre'} = $db->sqlSelect ("libelle.libelle","categorie_libelle_langue, libelle, langue","categorie_libelle_langue.ref_categorie = '$ARTICLE{'ref_categorie'}' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
        }
        
	$string .= "<tr><td align=\"left\"><img alt=\"\"  src=\"$ARTICLE{'image'}\"></td><td align=\"left\"><a href=\"/cgi-bin/detail.pl?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'author'}</td><td align=\"left\">$ARTICLE{'price'}</td></tr>";
    }
    $string .="</table>";    
    return $string;

    
}


sub loadDvdIndex {
    $lang = $query->param("lang") ;		
    my  $cat = shift || '';
    my  $type = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $depot = $query->param("depot");
    $depot =~ s/[^A-Za-z0-9 ]//;
    my $category = $query->param("category");
    my $subcat = $query->param("category");
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  $add;
    my  $add2;
    my  $dep;
    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");
    my $from;
    my $ref_cat;
    my $ref_subcat;
    if ($subcat) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcat' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $add .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
	
    if ($add eq "") {
	$add2 .= " and article.ref_categorie = 38";
    }	

    my  ($c)= $db->sqlSelect("count(id_article)",
			   "article,met_en_vente,categorie_libelle_langue $from",
			   "ref_article = id_article and article.ref_categorie = categorie_libelle_langue.ref_categorie AND met_en_vente.page_categorie  = 'on' AND ref_statut = '3' AND article.ref_categorie = categorie_libelle_langue.ref_categorie AND  enchere_date_fin > '$date% ' $add $add2");	
	

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
	$string .= "<a href=\"/cgi-bin/t.pl?lang=$lang&amp;page=dvd&session=$session_id&amp;min_index=$min_index&amp;max_index=$max_index&country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=with_lang_french&with_lang_italian=$with_lang_italian&amp;with_lang_german=with_lang_german&with_lang_english=$with_lang_english&category=$category&subcat=$subcat\"  ><-$j-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }
       if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }   
return $string; 

}

sub getMyArticleToDealIndex {
    my  $username = shift || '';	
    my  $client_id = shift || '';

    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  $statut = $query->param('statut');
    my  $add;
    
    if ($statut) {
	$add = "AND libelle.libelle = '$statut' AND article.ref_statut = statut_libelle_langue.ref_statut AND statut_libelle_langue.ref_libelle = libelle.id_libelle AND statut_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'";
	
   } else {
	$add = "AND article.ref_statut = statut_libelle_langue.ref_statut";
    }
    my  ($c)= $db->sqlSelectMany("article.nom,marque,label,libelle.libelle", "article,met_en_vente,personne,statut_libelle_langue, libelle, langue","ref_article = id_article and id_article = id_article AND met_en_vente.ref_vendeur = id_personne AND met_en_vente.ref_article = article.id_article AND nom_utilisateur = '$username' $add" );
    my  $id_command;	
	while(($id_command)=$c->fetchrow()) {
	    $total +=1;
	}
    my  $nb_page = arrondi ($total / 4, 1);
    my  $min_index = '0';
    my  $max_index = '40';
    
    for (my  $i = '0'; $i < $nb_page;$i++) {	
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=mydeal&amp;min_index=$min_index&amp;max_index=$max_index&amp;statut=$statut&session=$session_id\"  class=\"menulink2\" ><-$i-></a>&#160;&nbsp;";		
	$min_index += 40;
	
    }
      if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }
	return $string;
    	
}
sub getMyArticleToDealByIndex {
    
    my  $username = shift || '';
    my  $statut = $query->param('statut') ;
    my  $index_start = $query->param ("min_index");
    $index_start =~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index");
    $index_end =~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;

    my  $add;
    my  $add2;
        
    if (!$index_start ) {
	$index_start = 0;
    }
    if (!$index_end ) {
	$index_end = 40;
    }
    
    if ($statut) {
	$add = "AND libelle.libelle = '$statut' AND article.ref_statut = statut_libelle_langue.ref_statut AND statut_libelle_langue.ref_libelle = libelle.id_libelle AND statut_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'";
	
   } else {
	$add2 = "";		
    }

    my  ($c)= $db->sqlSelectMany("article.nom,marque,label,libelle.libelle", "article,met_en_vente,personne,statut_libelle_langue, libelle, langue","ref_article = id_article and id_article = id_article AND met_en_vente.ref_vendeur = id_personne AND met_en_vente.ref_article = article.id_article AND nom_utilisateur = '$username' AND ref_statut = id_statut $add2 LIMIT $index_start, $index_end" );	
    
    my  $string = "<table width=\"305\" border=\"0\"><tr bgcolor=\"#DBE4F8\"><td align=\"left\" width=\"51\">&nbsp;</td><td align=\"left\" width=\"47\">Titre</td><td align=\"left\" width=\"29\">Dj</td><td align=\"left\" width=\"54\">Label</td><td align=\"left\" width=\"90\">CHF en</td>";
    

    while( ($ARTICLE{'id_article'},$ARTICLE{'name'},$ARTICLE{'author'},$ARTICLE{'label'},$ARTICLE{'price'},$ARTICLE{'pochette'},$ARTICLE{'date_stock'},$ARTICLE{'genre'})=$c->fetchrow()) {
	$string .= "<tr><td align=\"left\"><td align=\"left\">$ARTICLE{'name'}</td><td align=\"left\">$ARTICLE{'author'}</td><td align=\"left\">$ARTICLE{'label'}</td><td align=\"left\">$ARTICLE{'statut'}</td><td align=\"left\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=detail&amp;article=$ARTICLE{'name'}&session=$session_id\">Detail</a></td></tr>";
    }
	$string .= "</table>";
    return $string;	
}


sub loadLastBuyersIndex {
    my $article = $query->param("article");  
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);


    
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  $add;

    my  ($c)= $db->sqlSelect("count(id_article)",
			   "article,a_paye",
			   "a_paye.ref_article = id_article AND a_paye.ref_statut = '7' AND id_article = $article");	
	
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
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=last_buyers&amp;article=$article&amp;session=$session_id&amp;min_index=$min_index&amp;max_index=$max_index\"  class=\"menulink2\" ><-$j-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }
  if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }        
return $string;    
}
sub loadDvdByIndex {
	loadLanguage();
    $lang = $query->param("lang") ;		
    my  $cat = shift || '';
    my  $type = shift  || '';
    my  $depot = $query->param("depot") ;
    $depot=~ s/[^A-Za-z0-9 ]//;
    my  $index_start = $query->param ("min_index");
    my $subcat = $query->param("category");
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index");
    $index_end =~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $string = "";
    my  $add;
    my $from;
    my $add2;
    my $category = $query->param("category");
    my $ref_cat;
    my $ref_subcat;
    if (!$index_start ) {$index_start = 0;}
    if (!$index_end ) {$index_end = 40;}
    if ($subcat) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcat' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $add .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
	
    if ($add eq "") {
	$add2 .= " AND (article.ref_categorie = 38)";
    }	
    my  ($c)= $db->sqlSelectMany("article.nom,id_article,marque,prix, categorie_libelle_langue.ref_categorie,pochette ",
		       "article,met_en_vente,categorie_libelle_langue, subcategorie_libelle_langue",
		       "ref_article = id_article  AND met_en_vente.notre_selection = '1'  AND ref_statut = '3' AND article.quantite > 0 and article.enchere_date_fin > '$date' AND categorie_libelle_langue.ref_categorie = article.ref_categorie AND subcategorie_libelle_langue.ref_subcategorie = article.ref_subcategorie $add  $add2 ORDER BY id_article DESC LIMIT $index_start, $index_end");	
    my $i = 0;my $j = 0;
    
	$string = "<table style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><tr style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"151\">$SERVER{'article_name_label'}</td><td align=\"left\">$SERVER{'fabricant'}</a></td><td align=\"left\">$SERVER{'article_price_label'}</td></tr>";
    

    
    
    while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'author'},$ARTICLE{'price'},$ARTICLE{'ref_categorie'},$ARTICLE{'image'})=$c->fetchrow()) {
	if ($ARTICLE{'image'} eq '') {
		##$ARTICLE{'image'} = "../images/blank.gif";
	}
        if ($ARTICLE{'ref_categorie'}) {
            $ARTICLE{'genre'} = $db->sqlSelect ("libelle.libelle","categorie_libelle_langue, libelle, langue","categorie_libelle_langue.ref_categorie = '$ARTICLE{'ref_categorie'}' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
        }
        
	$string .= "<tr><td align=\"left\"><img alt=\"\"  src=\"$ARTICLE{'image'}\"></td><td align=\"left\"><a href=\"/cgi-bin/detail.pl?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'author'}</td><td align=\"left\">$ARTICLE{'price'}</td></tr>";
    }
    $string .="</table>";    
    return $string;

}



sub loadBabyIndex {
    $lang = $query->param("lang") ;		
    my  $cat = shift || '';my  $type = shift || '';my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);my  $depot = $query->param("depot");$depot =~ s/\W//g;my $category = $query->param("category");
    my $subcat = $query->param("subcat");my  $string = "";my  $index = '0';my  $total = '0';my  $add;    my $from;
    if ($category) {$from .= ", categorie_libelle_langue, libelle, langue";
                    $add .= " AND libelle.libelle = '$category' AND article.ref_categorie = categorie_libelle_langue.ref_categorie AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'";}
    if ($subcat) {$from .= ", subcategorie_libelle_langue";
                    $add .= " AND subcategorie_libelle_langue.ref_subcategorie = (SELECT libelle.libelle FROM subcategorie_libelle_langue, libelle, langue WHERE libelle.libelle = '$subcat' AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang') AND article.ref_subcategorie = subcategorie_libelle_langue.ref_subcategorie";
                    }
    
    my $country_swiss = $query->param("country_swiss");my $country_france = $query->param("country_france");my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");my $with_lang_italian = $query->param("with_lang_italian");my $with_lang_english = $query->param("with_lang_english");
    my  ($c)= $db->sqlSelect("count(id_article)","article,met_en_vente $from","ref_article = id_article AND ref_statut = '3' AND  enchere_date_fin > '$date% ' AND quantite > 0 $add AND article.ref_categorie BETWEEN 58 AND 65");			
    my  $nb_page = arrondi ($c / 40, 1);my  $min_index = '0';my  $max_index = '40';    
    for (my  $i = '0'; $i < $nb_page;$i++) {my $j;if ($i <= 9) {$j = "0$i";}else {$j = $i;}
	$string .= "<a href=\"/cgi-bin/e.pl?lang=$lang&amp;page=baby&session=$session_id&amp;min_index=$min_index&amp;max_index=$max_index&country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=with_lang_french&with_lang_italian=$with_lang_italian&amp;with_lang_german=with_lang_german&with_lang_english=$with_lang_english\" ><-$j-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }
      if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }
return $string;    
}

sub loadBabyByIndex {
	loadLanguage();
    $lang = $query->param("lang") ;		
    my  $cat = shift || '';my  $type = shift  || '';my  $depot = $query->param("depot") ;$depot=~ s/[^A-Za-z0-9 ]//;
    my  $index_start = $query->param ("min_index");
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index");
    $index_end =~ s/[^A-Za-z0-9 ]//;
    my $category = $query->param("category");
    my $subcat = $query->param("subcat");
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    $date = trimwhitespace($date);
    my  $string = "";
    my  $add;
    my $from;
    if ($category) {$from .= "";
                    $add .= " AND libelle.libelle = '$category' AND article.ref_categorie = categorie_libelle_langue.ref_categorie AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'";}
    if ($subcat) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcat' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    my $ref_subcat = $sub_cat[0];
	    $add .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";

    } 
    if (!$index_start ) {$index_start = 0;}if (!$index_end ) {$index_end = 40;}
    #$add .= getAdd();    
        my  ($c)= $db->sqlSelectMany("DISTINCT(article.nom),id_article,marque,prix, categorie_libelle_langue.ref_categorie,pochette ",
		       "met_en_vente, article, categorie_libelle_langue, libelle, langue $from",
		       "ref_article = id_article  AND ref_statut = '3' and quantite > 0 AND  enchere_date_fin > "." '$date%' AND article.ref_categorie = 23 AND categorie_libelle_langue.ref_categorie = article.ref_categorie $add ORDER BY  date_stock DESC LIMIT $index_start, $index_end ");	

	my $i = 0;my $j = 0;
    my  $string = "<table style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><tr style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"151\">$SERVER{'article_name_label'}</td><td align=\"left\">$SERVER{'fabricant'}</a></td><td align=\"left\">$SERVER{'article_price_label'}</td></tr>";
    

    
    
    while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'author'},$ARTICLE{'price'},$ARTICLE{'ref_categorie'},$ARTICLE{'image'})=$c->fetchrow()) {
	if ($ARTICLE{'image'} eq '') {
		##$ARTICLE{'image'} = "../images/blank.gif";
	}
        if ($ARTICLE{'ref_categorie'}) {
            $ARTICLE{'genre'} = $db->sqlSelect ("libelle.libelle","categorie_libelle_langue, libelle, langue","categorie_libelle_langue.ref_categorie = '$ARTICLE{'ref_categorie'}' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
        }
        
	$string .= "<tr><td align=\"left\"><img alt=\"\"  src=\"$ARTICLE{'image'}\"></td><td align=\"left\"><a href=\"/cgi-bin/detail.pl?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'author'}</td><td align=\"left\">$ARTICLE{'price'}</td><</tr>";
    }
    $string .="</table>";    
    return $string;

}




sub loadEvalDealPositivIndex {
    my $username = $query->param("username");
    my ($c)= $db->sqlSelect("count(id_evaluation_vente)", "personne,evaluation_vente","nom_utilisateur = '$username' AND evaluation_vente.ref_vendeur = id_personne  AND note BETWEEN 5 AND 10");	
    my  $nb_page = arrondi ($c / 40, 1);
    my  $min_index = '0';
    my  $max_index = '40';
    my  $string;
    for (my  $i = '0'; $i < $nb_page;$i++) {
	my $n2 = $i %= 4;
	if ($n2 ne '0') {
	}
	$string .= "<a href=\"/cgi-bin/detail_dealer.pl?lang=$lang&amp;session=$session_id&page=profil_vendeur&username=$username&option=evaldeal&min_index=$min_index&max_index=$max_index\"  class=\"menulink2\" ><-$i-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }
      if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }
    return $string;
}
sub loadEvalDealPositivTable {
    my $content;
    my $username = $query->param("username");
    my  $index_start = $query->param ("min_index") ;
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index") ;
    $index_end=~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d",$year+1900,$mon+1,$mday;
    if (!$index_start ) {$index_start = 0;}
    if (!$index_end ) {$index_end = 40;}
    my	$string .= "<table width=\"500\" border=\"0\"><tr bgcolor=\"#DBE4F8\"><td align=\"left\">$SERVER{'buyer'}</td><td align=\"left\" >$SERVER{'commentaire'}</td><td>$SERVER{'note'}</td></tr>";
    my  ($c)= $db->sqlSelectMany("ref_acheteur,commentaire,note,date", "personne,evaluation_vente","nom_utilisateur = '$username' AND evaluation_vente.ref_vendeur = id_personne  AND note BETWEEN 5 AND 10 LIMIT $index_start, $index_end ");	
	 while( ($ARTICLE{'ref_acheteur'},$ARTICLE{'commentaire'},$ARTICLE{'note'},$ARTICLE{'date'})=$c->fetchrow()) {
		($ARTICLE{'acheteur'})= sqlSelect("nom_utilisateur", "personne","id_personne = $ARTICLE{'ref_acheteur'}");
		$string .= "<tr><td align=\"left\"><a href=\"/cgi-bin/detail_dealer.pl?lang=$lang&amp;session=$session_id&page=profil_vendeur&username=$ARTICLE{'acheteur'}&amp;option=evaldeal\" class=\"menulink\" >$ARTICLE{'acheteur'}</a></td><td>$ARTICLE{'commentaire'}</td><td>$ARTICLE{'note'}</td></tr>";
	}
    $string .="</table>";    
    return $string;

}

sub loadEvalBuyPositivIndex {
    my $username = $query->param("username");
    my  ($c)= $db->sqlSelect("count(id_evaluation_achat)", "personne,evaluation_achat","nom_utilisateur = '$username' AND evaluation_achat.ref_acheteur = id_personne  AND note BETWEEN 5 AND 10");	
    my  $nb_page = arrondi ($c / 40, 1);
    my  $min_index = '0';
    my  $max_index = '40';
    my $string;
    for (my  $i = '0'; $i < $nb_page;$i++) {
	my $n2 = $i %= 4;
	if ($n2 ne '0') {
		#$string .= "<br />";
	}
	$string .= "<a href=\"/cgi-bin/detail_dealer.pl?lang=$lang&amp;session=$session_id&page=profil_vendeur&username=$username&option=evalbuy&min_index=$min_index&max_index=$max_index\"  class=\"menulink2\" ><-$i-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }
  if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }    
    return $string;
}
sub loadEvalBuyPositivTable {
    my $content;
    my $username = $query->param("username");
	$lang = $query->param("lang");
    my  $index_start = $query->param ("min_index") ;
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index") ;
    $index_end=~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d",$year+1900,$mon+1,$mday;
    if (!$index_start ) {$index_start = 0;}
    if (!$index_end ) {$index_end = 40;}
    my	$string .= "<table width=\"500\" border=\"0\"><tr bgcolor=\"#DBE4F8\"><td align=\"left\">$SERVER{'dealer'}</td><td align=\"left\" >$SERVER{'commentaire'}</td><td>$SERVER{'note'}</td></tr>";
    my  ($c)= $db->sqlSelectMany("ref_vendeur,commentaire,note,date", "personne,evaluation_achat","nom_utilisateur = '$username' AND evaluation_achat.ref_acheteur = id_personne  AND note BETWEEN 5 AND 10 LIMIT $index_start, $index_end ");	
	 while( ($ARTICLE{'ref_vendeur'},$ARTICLE{'commentaire'},$ARTICLE{'note'},$ARTICLE{'date'})=$c->fetchrow()) {
		($ARTICLE{'vendeur'})= $db->sqlSelect("nom_utilisateur", "personne","id_personne = $ARTICLE{'ref_vendeur'}");
		$string .= "<tr><td align=\"left\"><a href=\"/cgi-bin/detail_dealer.pl?lang=$lang&amp;session=$session_id&page=profil_vendeur&username=$ARTICLE{'vendeur'}&amp;option=evalbuy\" class=\"menulink\" >$ARTICLE{'vendeur'}</a></td><td>$ARTICLE{'commentaire'}</td><td>$ARTICLE{'note'}</td></tr>";
	}
    $string .="</table>";    
    return $string;

}
sub loadEvalBuyNegativIndex {
    my $username = $query->param("username");
	$lang = $query->param("lang");
    my  ($c)= $db->sqlSelect("ref_vendeur,commentaire,note,date", "personne,evaluation_achat","nom_utilisateur = '$username' AND evaluation_achat.ref_acheteur = id_personne  AND note BETWEEN 0 AND 4");	   
    my  $nb_page = arrondi ($c / 40, 1);
    my  $min_index = '0';
    my  $max_index = '40';
    my $string;
    for (my  $i = '0'; $i < $nb_page;$i++) {
	my $n2 = $i %= 4;
	if ($n2 ne '0') {#$string .= "<br />";}
	$string .= "<a href=\"/cgi-bin/detail_dealer.pl?lang=$lang&amp;session=$session_id&page=profil_vendeur&username=$username&option=evalbuy&min_index=$min_index&max_index=$max_index\"  class=\"menulink2\" ><-$i-></a>&#160;&nbsp;";		
	$min_index += 40;	
}
}
}
sub loadEvalBuyNegativTable {
    my $content;
    my $username = $query->param("username");
	$lang = $query->param("lang");
    my  $index_start = $query->param ("min_index") ;
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index") ;
    $index_end=~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d",$year+1900,$mon+1,$mday;
    if (!$index_start ) {$index_start = 0;}
    if (!$index_end ) {$index_end = 40;}
    my	$string .= "<table width=\"500\" border=\"0\"><tr bgcolor=\"#DBE4F8\"><td align=\"left\">$SERVER{'dealer'}</td><td align=\"left\" >$SERVER{'commentaire'}</td><td>$SERVER{'note'}</td></tr>";
    my  ($c)= $db->sqlSelectMany("ref_vendeur,commentaire,note,date", "personne,evaluation_achat","nom_utilisateur = '$username' AND evaluation_achat.ref_acheteur = id_personne  AND note BETWEEN 0 AND 4 LIMIT $index_start, $index_end ");	
	 while( ($ARTICLE{'ref_vendeur'},$ARTICLE{'commentaire'},$ARTICLE{'note'},$ARTICLE{'date'})=$c->fetchrow()) {
		($ARTICLE{'vendeur'})= $db->sqlSelect("nom_utilisateur", "personne","id_personne = $ARTICLE{'ref_vendeur'}");
		$string .= "<tr><td align=\"left\"><a href=\"/cgi-bin/detail_dealer.pl?lang=$lang&amp;session=$session_id&page=profil_vendeur&username=$ARTICLE{'vendeur'}&amp;option=evalbuy\" class=\"menulink\" >$ARTICLE{'vendeur'}</a></td><td>$ARTICLE{'commentaire'}</td><td>$ARTICLE{'note'}</td></tr>";
	}
    $string .="</table>";    
    return $string;

}

sub loadGamesByIndex {
	loadLanguage();
    $lang = $query->param("lang") ;		
    my  $cat = shift || '';
    my  $type = shift  || '';
    my  $depot = $query->param("depot") ;
    $depot=~ s/[^A-Za-z0-9 ]//;
    my  $index_start = $query->param ("min_index");
    my $subcat = $query->param("subcat");
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index");
    $index_end =~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $string = "";
    my  $add;
    my $from;
    my $add2;
    my $category = $query->param("category");
    my $ref_cat;
    my $ref_subcat;
    if (!$index_start ) {$index_start = 0;}
    if (!$index_end ) {$index_end = 40;}
    if ($category) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $add .= " AND article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
    }
    if ($subcat) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcat' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $add .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
	
    if ($add eq "") {
	$add2 .= " AND (article.ref_categorie = 11 or article.ref_categorie = 95)";
    }	
    
    my  ($c)= $db->sqlSelectMany("article.nom,id_article,marque,prix, categorie_libelle_langue.ref_categorie,pochette ",
		       "article,met_en_vente,categorie_libelle_langue, subcategorie_libelle_langue",
		       "ref_article = id_article  AND met_en_vente.notre_selection = '1'  AND ref_statut = '3' AND article.quantite > 0 and article.enchere_date_fin > '$date' AND categorie_libelle_langue.ref_categorie = article.ref_categorie AND subcategorie_libelle_langue.ref_subcategorie = article.ref_subcategorie $add  $add2 ORDER BY id_article DESC LIMIT $index_start, $index_end");	
    
	my $i = 0;my $j = 0;
    $string = "<table style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><tr style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"151\">$SERVER{'article_name_label'}</td><td align=\"left\">$SERVER{'fabricant'}</a></td><td align=\"left\">$SERVER{'article_price_label'}</td></tr>";
    
    while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'author'},$ARTICLE{'price'},$ARTICLE{'ref_categorie'},$ARTICLE{'image'})=$c->fetchrow()) {
	if ($ARTICLE{'image'} eq '') {
		##$ARTICLE{'image'} = "../images/blank.gif";
	}
        if ($ARTICLE{'ref_categorie'}) {
            $ARTICLE{'genre'} = $db->sqlSelect ("libelle.libelle","categorie_libelle_langue, libelle, langue","categorie_libelle_langue.ref_categorie = '$ARTICLE{'ref_categorie'}' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
        }
        
	$string .= "<tr><td align=\"left\"><img alt=\"\"  src=\"$ARTICLE{'image'}\"></td><td align=\"left\"><a href=\"/cgi-bin/detail.pl?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'author'}</td><td align=\"left\">$ARTICLE{'price'}</td></tr>";
    }
    $string .="</table>";    
    return $string;

    
}


sub loadMultimediaInformatiqueIndex {
    $lang = $query->param("lang") ;		
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
    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");
    my  $add2;
    
    my $ref_cat;
    my $ref_subcat;
    if ($category) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $add .= " AND article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
    }
    if ($subcat) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcat' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $add .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
	
    if ($add eq "") {
	$add2 .= " AND article.ref_categorie = 7";
    }	

    my  ($c)= $db->sqlSelect("count(id_article)",
			   "article,met_en_vente, categorie_libelle_langue $from",
			   "ref_article = id_article AND ref_statut = '3' AND  enchere_date_fin > '$date% ' AND quantite > 0 $add $add2");	
	
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
	$string .= "<a href=\"/cgi-bin/q.pl?lang=$lang&amp;page=tv_video&amp;session=$session_id&amp;min_index=$min_index&amp;max_index=$max_index&amp;country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=with_lang_french&amp;with_lang_italian=$with_lang_italian&amp;with_lang_german=with_lang_german&amp;with_lang_english=$with_lang_english\"  ><-$j-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }
  if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }        
return $string;    

}
sub loadMultimediaInformatiqueByIndex {
	loadLanguage();
    $lang = $query->param("lang") ;		
    my  $cat = shift || '';
    my  $type = shift  || '';
    my  $depot = $query->param("depot") ;
    $depot=~ s/[^A-Za-z0-9 ]//;
    my  $index_start = $query->param ("min_index");
    my $subcat = $query->param("subcat");
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index");
    $index_end =~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $string = "";
    my  $add;
    my $from;
    my $add2;
    my $category = $query->param("category");
    my $ref_cat;
    my $ref_subcat;
    if (!$index_start ) {$index_start = 0;}
    if (!$index_end ) {$index_end = 40;}
    if ($category) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $add .= " AND article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
    }
    if ($subcat) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcat' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $add .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
	
    if ($add eq "") {
	$add2 .= " AND article.ref_categorie = 7";
    }
	
        my  ($c)= $db->sqlSelectMany("article.nom,id_article,marque,prix, categorie_libelle_langue.ref_categorie,pochette ",
		       "article,met_en_vente,categorie_libelle_langue, subcategorie_libelle_langue",
		       "ref_article = id_article  AND met_en_vente.notre_selection = '1'  AND ref_statut = '3' AND article.quantite > 0 and article.enchere_date_fin > '$date' AND categorie_libelle_langue.ref_categorie = article.ref_categorie AND subcategorie_libelle_langue.ref_subcategorie = article.ref_subcategorie $add  $add2 ORDER BY id_article DESC LIMIT $index_start, $index_end");	

	 $string = "<table style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><tr style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"151\">$SERVER{'article_name_label'}</td><td align=\"left\">$SERVER{'fabricant'}</a></td><td align=\"left\">$SERVER{'article_price_label'}</td></tr>";


    my $i = 0;my $j = 0;

    
    while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'author'},$ARTICLE{'price'},$ARTICLE{'ref_categorie'},$ARTICLE{'image'})=$c->fetchrow()) {
	if ($ARTICLE{'image'} eq '') {
		##$ARTICLE{'image'} = "../images/blank.gif";
	}
        if ($ARTICLE{'ref_categorie'}) {
            $ARTICLE{'genre'} = $db->sqlSelect ("libelle.libelle","categorie_libelle_langue, libelle, langue","categorie_libelle_langue.ref_categorie = '$ARTICLE{'ref_categorie'}' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
        }
        
	$string .= "<tr><td align=\"left\"><img alt=\"\"  src=\"$ARTICLE{'image'}\"></td><td align=\"left\"><a href=\"/cgi-bin/detail.pl?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'author'}</td><td align=\"left\">$ARTICLE{'price'}</td></tr>";
    }
    $string .="</table>";    
    return $string;

    
}

 sub loadArticleBabyIndex {
    $lang = $query->param("lang");
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
    my  $add2;
    my  $dep;
    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");
    my $from;
    my $ref_cat;
    my $ref_subcat;
    if ($category) {            
	    $ref_cat = 23;
	    $add .= " AND article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
    }
    if ($subcat) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcat' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $add .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
	
    if ($add eq "") {
	$add2 .= " and article.ref_categorie = 23";
    }	

    my  ($c)= $db->sqlSelect("count(id_article)",
			   "article,met_en_vente,categorie_libelle_langue $from",
			   "ref_article = id_article and article.ref_categorie = categorie_libelle_langue.ref_categorie AND met_en_vente.page_categorie  = 'on' AND ref_statut = '3' AND article.ref_categorie = categorie_libelle_langue.ref_categorie AND  enchere_date_fin > '$date% ' $add $add2");	
	

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
	$string .= "<a href=\"/cgi-bin/e.pl?lang=$lang&amp;page=baby&session=$session_id&amp;min_index=$min_index&amp;max_index=$max_index&country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=with_lang_french&with_lang_italian=$with_lang_italian&amp;with_lang_german=with_lang_german&with_lang_english=$with_lang_english&category=$category&subcat=$subcat\" ><-$j-></a>&#160;&nbsp;";
	$min_index += 40;	
    }
    if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }        
return $string;
}

 sub loadWearIndex {
    $lang = $query->param("lang") ;	 
    my  $cat = shift || '';
    my  $type = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $depot = $query->param("depot");
    $depot =~ s/[^A-Za-z0-9 ]//;
    my $sex = $query->param("sex");
    my $subcat = $query->param("subcat");
    my $category = $query->param("sex");
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  $add;
    my  $add2;
    my  $dep;
    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");
    my $from;
    my $ref_cat;
    my $ref_subcat;
    if ($sex) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$sex' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $add .= " AND article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
    }
    if ($subcat) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcat' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $add .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
	
    if ($add eq "") {
	$add2 .= " and article.ref_categorie between 1 and 2";
    }	

    my  ($c)= $db->sqlSelect("count(id_article)",
			   "article,met_en_vente,categorie_libelle_langue $from",
			   "ref_article = id_article and article.ref_categorie = categorie_libelle_langue.ref_categorie AND met_en_vente.page_categorie  = 'on' AND ref_statut = '3' AND article.ref_categorie = categorie_libelle_langue.ref_categorie AND  enchere_date_fin > '$date% ' $add $add2");	
	

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
	$string .= "<a href=\"/cgi-bin/c.pl?lang=$lang&amp;page=wear_news&session=$session_id&amp;min_index=$min_index&amp;max_index=$max_index&country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=with_lang_french&with_lang_italian=$with_lang_italian&amp;with_lang_german=with_lang_german&with_lang_english=$with_lang_english&category=$category&subcat=$subcat\" ><-$j-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }
    if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }        
return $string;    
}

sub loadAstrologieIndex {
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
    my  $add2;
    my  $dep;
    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");
    my $from;
    my $ref_cat;
    my $ref_subcat;
    if ($category) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $add .= " AND article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
    }
    if ($subcat) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcat' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $add .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
	
    if ($add eq "") {
	$add2 .= " and article.ref_categorie = 32";
    }	

    my  ($c)= $db->sqlSelect("count(id_article)",
			   "article,met_en_vente,categorie_libelle_langue $from",
			   "ref_article = id_article and article.ref_categorie = categorie_libelle_langue.ref_categorie AND met_en_vente.page_categorie  = 'on' AND ref_statut = '3' AND article.ref_categorie = categorie_libelle_langue.ref_categorie AND  enchere_date_fin > '$date% ' $add $add2");	
	

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
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=wear_news&session=$session_id&amp;min_index=$min_index&amp;max_index=$max_index&country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=with_lang_french&with_lang_italian=$with_lang_italian&amp;with_lang_german=with_lang_german&with_lang_english=$with_lang_english&category=$category&subcat=$subcat\"  class=\"menulink2\" ><-$j-></a>&#160;&nbsp;";		
	$min_index += 40;	
    } 
    if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }        
return $string;    
}

sub loadAnimalIndex {
    $lang = $query->param("lang") ;		
    my  $cat = shift || '';my  $type = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $depot = $query->param("depot");
    $depot =~ s/[^A-Za-z0-9 ]//;
    my $category = $query->param("category");
    my $subcat = $query->param("subcat");
    my  $string = "";my  $index = '0';my  $total = '0';my  $add;my $from;
    my  $add2;
    my $ref_cat;
    my $ref_subcat;

    if ($category) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $from .= ", categorie_libelle_langue";
	    $add .= " AND article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
    }
    if ($subcat) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcat' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $add .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
	
    if ($add eq "") {
	$add2 .= " AND article.ref_categorie = 33";
    }	
    my $country_swiss = $query->param("country_swiss"); my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french"); my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian"); my $with_lang_english = $query->param("with_lang_english");

    my  ($c)= $db->sqlSelect("count(id_article)","article,met_en_vente $from","ref_article = id_article AND ref_statut = '3' AND  enchere_date_fin > '$date% ' AND quantite > 0 $add $add2");		
    my  $nb_page = arrondi ($c / 40, 1);
    my  $min_index = '0';my  $max_index = '40';    
    for (my  $i = '0'; $i < $nb_page;$i++) {		
	my $j;
	if ($i <= 9) {$j = "0$i";}else {$j = $i;}
	$string .= "<a href=\"/cgi-bin/f.pl?lang=$lang&amp;page=animal&amp;session=$session_id&amp;min_index=$min_index&amp;max_index=$max_index&country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=with_lang_french&with_lang_italian=$with_lang_italian&amp;with_lang_german=with_lang_german&with_lang_english=$with_lang_english&subcat=$subcat&category=$category\" ><-$j-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }
    if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }    
    return $string;     
}

sub loadAnimalByIndex {
	loadLanguage();
    $lang = $query->param("lang") ;		
    my  $cat = shift || '';my  $type = shift  || '';my  $depot = $query->param("depot") ;$depot=~ s/[^A-Za-z0-9 ]//;
    my  $index_start = $query->param ("min_index");$index_start=~ s/[^A-Za-z0-9 ]//;my  $index_end = $query->param ("max_index");$index_end =~ s/[^A-Za-z0-9 ]//;
    my $category = $query->param("category");my $subcat = $query->param("subcat");my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    $date = trimwhitespace($date);my  $string = "";my  $add;my $from;
    my  $add2;
    my $ref_cat;
    my $ref_subcat;

    if ($category) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $add .= " AND article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
    }
    if ($subcat) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcat' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $add .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
	
    if ($add eq "") {
	$add2 .= " AND article.ref_categorie = 33";
    }	
    
    if (!$index_start ) {$index_start = 0;}
    if (!$index_end ) {$index_end = 40;}

   

        my  ($c)= $db->sqlSelectMany("article.nom,id_article,marque,prix, categorie_libelle_langue.ref_categorie,pochette ",
		       "article,met_en_vente,categorie_libelle_langue, subcategorie_libelle_langue",
		       "ref_article = id_article  AND met_en_vente.notre_selection = '1'  AND ref_statut = '3' AND article.quantite > 0 and article.enchere_date_fin > '$date $time' AND categorie_libelle_langue.ref_categorie = article.ref_categorie AND subcategorie_libelle_langue.ref_subcategorie = article.ref_subcategorie $add  $add2 ORDER BY id_article DESC LIMIT $index_start, $index_end");	

    my $i = 0;my $j = 0;

    my $string = "<table style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><tr style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"151\">$SERVER{'article_name_label'}</td><td align=\"left\">$SERVER{'fabricant'}</a></td><td align=\"left\">$SERVER{'article_price_label'}</td></tr>";
    

    
    
    while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'author'},$ARTICLE{'price'},$ARTICLE{'ref_categorie'},$ARTICLE{'image'})=$c->fetchrow()) {
	if ($ARTICLE{'image'} eq '') {
		##$ARTICLE{'image'} = "../images/blank.gif";
	}
        if ($ARTICLE{'ref_categorie'}) {
            $ARTICLE{'genre'} = $db->sqlSelect ("libelle.libelle","categorie_libelle_langue, libelle, langue","categorie_libelle_langue.ref_categorie = '$ARTICLE{'ref_categorie'}' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
        }
        
	$string .= "<tr><td align=\"left\"><img alt=\"\"  src=\"$ARTICLE{'image'}\"></td><td align=\"left\"><a href=\"/cgi-bin/detail.pl?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'author'}</td><td align=\"left\">$ARTICLE{'price'}</td></tr>";
    }
    $string .="</table>";    
    return $string;
  
}
sub arrondi {
     my  $n = shift;
     $n = int($n + 0.5);
     if ($n < 1) {
	$n = 1;
     }
     
     return $n;
}

sub trimwhitespace($) {
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}


sub loadArticleOnlyEnchIndex {
    
    my  $cat = shift || '';
    my  $type = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d",$hour);
    my  $depot = $query->param("depot");
    $depot =~ s/[^A-Za-z0-9 ]//;
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  $add;
    $date = trimwhitespace($date);
    $time = trimwhitespace($time);
    if ($time eq '0' or $time eq '1' or $time eq '2' or $time eq '3' or $time eq '4' or $time eq '5' or $time eq '6' or $time eq '7' or $time eq '8' or $time eq '9') {
	$time = "0" .$time;
    }

    my  $add2;
    my  $dep;
    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");

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
	$add .= getAdd();
    

    my  ($c)= sqlSelect("count(article.nom)",
			   "article",
			   "enchere_date_fin > '$date%' AND ref_statut = '3' and enchere = 1 $add");	
	

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
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&amp;min_index_last_hour=$min_index&amp;max_index_last_hour=$max_index&amp;country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=$with_lang_french&amp;with_lang_german=$with_lang_german&amp;with_lang_italian=$with_lang_italian&amp;with_lang_english=$with_lang_english&saw=onlyench\"  class=\"menulink2\" ><-$j-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }
    if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }        
return $string;    
}

sub loadWearByIndex {
	loadLanguage();
    $lang = $query->param("lang") ;	
    my  $cat = shift || '';
    my  $type = shift  || '';
    my  $depot = $query->param("depot") ;
    $depot=~ s/[^A-Za-z0-9 ]//;
    my  $index_start = $query->param ("min_index");
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index");
    $index_end =~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my $sex = $query->param("sex");
    my $subcat = $query->param("subcat");
    my $from .= "";
    my  $add = "";
    my $ref_cat;
    my $ref_subcat;
    if ($sex) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$sex' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $add .= " AND article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
    }
    if ($subcat) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcat' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $add .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
    my  $string = "";    my  $add2;
    my  $dep;
    
    if (!$index_start ){$index_start = 0;}
    if (!$index_end ) {$index_end = 40;}
    
    if ($add eq "") {
	$add2 = " and article.ref_categorie between 1 and 2 "
    }
    
    my  ($c)= $db->sqlSelectMany("DISTINCT(article.nom),id_article,marque,prix, categorie_libelle_langue.ref_categorie,pochette ",
		       "met_en_vente, article, categorie_libelle_langue, libelle, langue $from",
		       "ref_article = id_article and article.ref_categorie = categorie_libelle_langue.ref_categorie AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND met_en_vente.page_categorie = 'on' AND ref_statut = '3'  AND  article.ref_categorie = categorie_libelle_langue.ref_categorie AND enchere_date_fin > "." '$date%'  $add $add2 ORDER BY  date_stock DESC LIMIT $index_start, $index_end");	
    
    my $i = 0;my $j = 0;
    $string = "<table style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><tr style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"151\">$SERVER{'article_name_label'}</td><td align=\"left\">$SERVER{'fabricant'}</a></td><td align=\"left\">$SERVER{'article_price_label'}</td></tr>";
    

    
    
    while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'author'},$ARTICLE{'price'},$ARTICLE{'ref_categorie'},$ARTICLE{'image'})=$c->fetchrow()) {
	if ($ARTICLE{'image'} eq '') {
		##$ARTICLE{'image'} = "../images/blank.gif";
	}
        if ($ARTICLE{'ref_categorie'}) {
            $ARTICLE{'genre'} = $db->sqlSelect ("libelle.libelle","categorie_libelle_langue, libelle, langue","categorie_libelle_langue.ref_categorie = '$ARTICLE{'ref_categorie'}' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
        }
        
	$string .= "<tr><td align=\"left\"><img alt=\"\"  src=\"$ARTICLE{'image'}\"></td><td align=\"left\"><a href=\"/cgi-bin/detail.pl?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'author'}</td><td align=\"left\">$ARTICLE{'price'}</td></tr>";
    }
    $string .="</table>";    
    return $string;

    
}
sub loadAstologieByIndex {
    my  $cat = shift || '';
    my  $type = shift  || '';
    my  $depot = $query->param("depot") ;
    $depot=~ s/[^A-Za-z0-9 ]//;
    my  $index_start = $query->param ("min_index");
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index");
    $index_end =~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my $category = $query->param("category");
    my $subcat = $query->param("subcat");
    my $from .= "";
    my  $add = "";
    my $ref_cat;
    my $ref_subcat;
    if ($category) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $add .= " AND article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
    }
    if ($subcat) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcat' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $add .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
    my  $string = "";    my  $add2;
    my  $dep;
    
    if (!$index_start ){$index_start = 0;}
    if (!$index_end ) {$index_end = 40;}
    
    if ($add eq "") {
	$add2 = " and article.ref_categorie = 32 "
    }
    
    my  ($c)= $db->sqlSelectMany("DISTINCT id_article,article.nom,marque,prix, pochette,date_stock,libelle.libelle",
		       "met_en_vente, article, categorie_libelle_langue, libelle, langue $from",
		       "ref_article = id_article and article.ref_categorie = categorie_libelle_langue.ref_categorie AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND met_en_vente.page_categorie = 'on' AND ref_statut = '3'  AND  article.ref_categorie = categorie_libelle_langue.ref_categorie AND enchere_date_fin > "." '$date%'  $add $add2 ORDER BY  date_stock DESC LIMIT $index_start, $index_end");	
    
    my $i = 0;my $j = 0;$string .= "<table style=\"border-top-width:medium;border-top-color:#94CEFA\"><tr>";    
    while( ($ARTICLE{'id_article'},$ARTICLE{'name'},$ARTICLE{'author'},$ARTICLE{'price'},$ARTICLE{'pochette'},$ARTICLE{'date'},$ARTICLE{'ref_categorie'})=$c->fetchrow()) {
	#$string .= " <label>&nbsp;&nbsp;$ARTICLE{'genre'}</label>";
	if ($ARTICLE{'pochette'} eq '') {$ARTICLE{'pochette'} = "../images/no.gif";}
	my $add3;
	if ($ARTICLE{'ref_categorie'} eq '11') {$add3 = $ARTICLE{'article_lieu'};}
	my $img;
	if ($ARTICLE{'date'} eq $date) {$img = "../images/new_article.gif"}else {}
	$string .= "<td align=\"left\" width=\"255px\" height=\"152px\" style=\"background-image:url(../images/table_article_decoration.jpg);background-position:right bottom;background-repeat: no-repeat; border-width:thin;\">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&amp;action=detailother&amp;article=$ARTICLE{'id_article'}\" class=\"menulink3\" >$ARTICLE{'name'} $add3</a><br/>&nbsp;&nbsp;&nbsp;&nbsp;<img alt=\"\" src=\"$ARTICLE{'pochette'}\" /> <img alt=\"\" src=\"$img\" /><br/>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$ARTICLE{'price'} <br/><br/></td>";
	$i += 1;$j += 1;
	if ($i eq 1) {$string .= "<td align=\"left\" width=\"10px\"></td>";$i = 0;}	
	if ($j eq 2) {$string .= "</tr>";$string .= "<tr>";$string .= "</tr>";$string .= "<tr>";$string .= "</tr>";$string .= "<tr>";$j = 0;}
    }    
    $string .= "</table>";
    return $string;
    
}
sub loadBabyByIndexTEST {
    my  $cat = shift || '';
    my  $type = shift  || '';
    my  $depot = $query->param("depot") ;
    $depot=~ s/[^A-Za-z0-9 ]//;
    my  $index_start = $query->param ("min_index");
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index");
    $index_end =~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my $category = $query->param("category");
    my $subcat = $query->param("subcat");
    my $from .= "";
    my  $add = "";
    my $ref_cat;
    my $ref_subcat;
    if ($category) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $add .= " AND article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
    }
    if ($subcat) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcat' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $add .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
    my  $string = "";    my  $add2;
    my  $dep;
    
    if (!$index_start ){$index_start = 0;}
    if (!$index_end ) {$index_end = 40;}
    
    if ($add eq "") {
	$add2 = " and article.ref_categorie = 23 "
    }
    
    my  ($c)= $db->sqlSelectMany("DISTINCT id_article,article.nom,marque,prix, pochette,date_stock,libelle.libelle",
		       "met_en_vente, article, categorie_libelle_langue, libelle, langue $from",
		       "ref_article = id_article and article.ref_categorie = categorie_libelle_langue.ref_categorie AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND met_en_vente.page_categorie = 'on' AND ref_statut = '3'  AND  article.ref_categorie = categorie_libelle_langue.ref_categorie AND enchere_date_fin > "." '$date%'  $add $add2 ORDER BY  date_stock DESC LIMIT $index_start, $index_end");	
    
    my $i = 0;my $j = 0;$string .= "<table style=\"border-top-width:medium;border-top-color:#94CEFA\"><tr>";    
    while( ($ARTICLE{'id_article'},$ARTICLE{'name'},$ARTICLE{'author'},$ARTICLE{'price'},$ARTICLE{'pochette'},$ARTICLE{'date'},$ARTICLE{'ref_categorie'})=$c->fetchrow()) {
	#$string .= " <label>&nbsp;&nbsp;$ARTICLE{'genre'}</label>";
	if ($ARTICLE{'pochette'} eq '') {$ARTICLE{'pochette'} = "../images/no.gif";}
	my $add3;
	if ($ARTICLE{'ref_categorie'} eq '11') {$add3 = $ARTICLE{'article_lieu'};}
	my $img;
	if ($ARTICLE{'date'} eq $date) {$img = "../images/new_article.gif"}else {}
	$string .= "<td align=\"left\" width=\"255px\" height=\"152px\" style=\"background-image:url(../images/table_article_decoration.jpg);background-position:right bottom;background-repeat: no-repeat; border-width:thin;\">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&amp;action=detailother&amp;article=$ARTICLE{'id_article'}\" class=\"menulink3\" >$ARTICLE{'name'} $add3</a><br/>&nbsp;&nbsp;&nbsp;&nbsp;<img alt=\"\" src=\"$ARTICLE{'pochette'}\" /> <img alt=\"\" src=\"$img\" /><br/>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$ARTICLE{'price'} <br/><br/></td>";
	$i += 1;$j += 1;
	if ($i eq 1) {$string .= "<td align=\"left\" width=\"10px\"></td>";$i = 0;}	
	if ($j eq 2) {$string .= "</tr>";$string .= "<tr>";$string .= "</tr>";$string .= "<tr>";$string .= "</tr>";$string .= "<tr>";$j = 0;}
    }    
    $string .= "</table>";
    return $string;
    
}

sub loadCommandIndex {
    my  $client_id = shift || '';

    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  ($c)= sqlSelectMany("id_commande,session_ID,date, date_payement",
			   "commande",
			   "client_ref = $client_id");	
    my  $id_command;	
	while(($id_command)=$c->fetchrow()) {
	    $total +=1;
	}
    my  $nb_page = arrondi ($total / 4, 1);
    my  $min_index = '0';
    my  $max_index = '40';
    
    for (my  $i = '0'; $i < $nb_page;$i++) {	
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&page=mycommand&amp;min_index=$min_index&amp;max_index=$max_index\"  class=\"menulink2\" ><-$i-></a>&#160;&nbsp;";		
	$min_index += 40;
	
    }
  if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }
	return $string;
    
}

sub loadCommandByIndex {
    my  $index_start = $query->param ("min_index");
    $index_start =~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index");
    $index_end =~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;

    my  $client_id = shift || '';
    
    if (!$index_start ) {
	$index_start = 0;
    }
    if (!$index_end ) {
	$index_end = 40;
    }
    
    my  ($c)= sqlSelectMany("id_commande,session_ID,date, date_payement",
		       "commande",
		        "client_ref = $client_id LIMIT $index_start, $index_end");	
    
    my  $string = "<table width=\505\" border=\"0\"><tr bgcolor=\"#DBE4F8\"><td align=\"left\" width=\"51\">$SERVER{'id_commande'}</td><td align=\"left\">$SERVER{'session_ID'}</td><td align=\"left\">$SERVER{'date'}</td><td align=\"left\" width=\"181\">$SERVER{'date_payement'}</td></tr>";
    

    while( ($COMMAND{'id_commande'},$COMMAND{'session_ID'}, $COMMAND{'date'}, $COMMAND{'date_payement'})=$c->fetchrow()) {
	$string .= "<tr><td align=\"left\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&amp;action=mycommandetail&amp;commandID=$COMMAND{'id_commande'}\">$COMMAND{'id_commande'}</a></td><td align=\"left\">$COMMAND{'session_ID'}</td><td align=\"left\">$COMMAND{'date'}</td><td align=\"left\">$COMMAND{'date_payement'}</td></tr>";
    }
    $string .="</table>";
    return $string;
    
}

sub loadCommandDetailIndex {
    
    my  $command_id = shift || '';

    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $string = "";
    my  $index = '0';
    my  $total = '0';#ajouter la r�f�rence � l'acheteur
    my  ($c)= sqlSelectMany("ref_article",
			   "commande_article",
			   "ref_commande = $command_id");	
    my  $id_command;	
	while(($id_command)=$c->fetchrow()) {
	    $total +=1;
	}
    my  $nb_page = arrondi ($total / 4, 1);
    my  $min_index = '0';
    my  $max_index = '40';
    
    for (my  $i = '0'; $i < $nb_page;$i++) {	
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;amp;action=detail_command_article&amp;command=$command_id&amp;min_index=$min_index&amp;max_index=$max_index\"><-$i-></a>&#160;&nbsp;";		
	$min_index += 40;
	
    }
  if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }
	return $string;
        
}

sub loadCommandDetailByIndex {
    my  $index_start = $query->param ("min_index");
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index") ;
    $index_end=~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;

    my  $command_id = shift || '';
    
    if (!$index_start ) {$index_start = 0;}
    if (!$index_end ) {$index_end = 40;}
    
    my  $string = "<table width=\"305\" border=\"0\"><tr bgcolor=\"#DBE4F8\"><td align=\"left\" width=\"51\">&nbsp;</td><td align=\"left\" width=\"47\">Titre</td><td align=\"left\" width=\"29\">Dj</td><td align=\"left\" width=\"54\">Label</td><td align=\"left\" width=\"90\">CHF en</td>";
    my  $amount = ();
    if ($command_id) {
	my  ($c)= sqlSelectMany("nom,marque,label,prix",
			       "article,commande_article,commande",
			       "ref_article = id_article and id_article = id_article AND commande_article.ref_article = id_article AND id_commande = $command_id AND commande_article.ref_commande = id_commande and commande_article.date_payement LIMIT $index_start, $index_end");	
	    while( ($ARTICLE{'name'},$ARTICLE{'author'},$ARTICLE{'label'},$ARTICLE{'price'})=$c->fetchrow()) {
		$string .= "<tr><td align=\"left\"><td align=\"left\">$ARTICLE{'name'}</td><td align=\"left\">$ARTICLE{'author'}</td><td align=\"left\">$ARTICLE{'label'}</td><td align=\"left\">$ARTICLE{'price'}</td></tr>";
		$amount +=$ARTICLE{'price'};	    	    
	    }
	    $string .="</table><br />";
    }else {
	loadPage ();
    }
	return $string;    
    
}

sub viewArticleNewsByIndex {
    my  $cat = shift || '';
    my  $type = shift  || '';
    my  $depot = $query->param("depot") ;
    $depot=~ s/[^A-Za-z0-9 ]//;
    my  $index_start = $query->param ("min_index");
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index");
    $index_end =~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    $date = trimwhitespace($date);
    my  $string = "";
    my  $add;
    my  $add2;
    my  $dep;
    
    if (!$index_start ) {$index_start = 0; }
    if (!$index_end ) {$index_end = 40;}

    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");

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
     $add .= getAdd();

    my  ($c)= sqlSelectMany("DISTINCT article.nom,marque,prix, pochette,id_article,date_stock,ref_categorie,article.lieu,quantite",
		       "article,met_en_vente",
		       "ref_article = id_article  AND ref_statut = '3' and quantite > 0 AND  enchere_date_fin > "." '$date%'  $add ORDER BY  date_stock DESC LIMIT $index_start, $index_end  ");	    
    my $i = 0; my $j = 0;
    $string .= "<table style=\"border-top-width:medium;border-top-color:#94CEFA\"><tr>";   
    while( ($ARTICLE{'name'},$ARTICLE{'author'},$ARTICLE{'price'},$ARTICLE{'pochette'},$ARTICLE{'id_article'},$ARTICLE{'date'},$ARTICLE{'ref_categorie'},$ARTICLE{'article_lieu'},$ARTICLE{'quantity'})=$c->fetchrow()) {
	#$string .= " <label>&nbsp;&nbsp;$ARTICLE{'genre'}</label>";
	my $img;
	if ($ARTICLE{'pochette'} eq '') {$ARTICLE{'pochette'} = "../images/blank.gif";}	
	if ($ARTICLE{'date'} eq $date) {$img = "../images/new_article.gif"}else {}
	my $add3;
	if ($ARTICLE{'ref_categorie'} eq '11') {$add3 = $ARTICLE{'article_lieu'};}
	$string .= "<td align=\"left\" width=\"253px\" height=\"100px\" style=\"ba00ckground-image:url(../images/table_article_decoration.jpg);background-position:right bottom;background-repeat: no-repeat;\">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&amp;action=detailother&amp;article=$ARTICLE{'id_article'}\" class=\"menulink3\" >$ARTICLE{'name'} $add3</a><br/>&nbsp;&nbsp;&nbsp;&nbsp;<img alt=\"\" src=\"$ARTICLE{'pochette'}\" /> <img alt=\"\" src=\"$img\" /><br/>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$ARTICLE{'price'} <br/><br/></td>";
	$i += 1;$j += 1;
	if ($i eq 1) {$string .= "<td align=\"left\" width=\"10px\"></td>";$i = 0;}	
	if ($j eq 2) {$string .= "</tr><tr>";$j = 0;}
    }    
    $string .= "</tr></table>";
    return $string;
    
}

sub loadArticleOnlyEnchByIndex {
    loadLanguage();
    my  $cat = shift || '';
    my  $type = shift  || '';
    my  $depot = $query->param("depot") ;
    $depot=~ s/[^A-Za-z0-9 ]//;
    my  $index_start = $query->param ("min_index");
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index");
    $index_end =~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    $date = trimwhitespace($date);
    my  $string = "";
    my  $add;
    my  $add2;
    my  $dep;
    
    if (!$index_start ) {$index_start = 0; }
    if (!$index_end ) {$index_end = 40;}

    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");

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
     $add .= getAdd();

    my  ($c)= sqlSelectMany1("DISTINCT article.nom,marque,prix, pochette,id_article,date_stock,ref_categorie,article.lieu,quantite",
		       "article,met_en_vente",
		       "ref_article = id_article AND ref_statut = '3' and quantite > 0 AND  enchere_date_fin > '$date%' and enchere = 1 $add ORDER BY  date_stock DESC LIMIT $index_start, $index_end  ");	    
    my $i = 0; my $j = 0;
    $string = "<table style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><tr style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"151\">$SERVER{'article_name_label'}</td><td align=\"left\">$SERVER{'fabricant'}</a></td><td align=\"left\">$SERVER{'article_price_label'}</td></tr>";
    while( ($ARTICLE{'name'},$ARTICLE{'author'},$ARTICLE{'price'},$ARTICLE{'pochette'},$ARTICLE{'id_article'},$ARTICLE{'date'},$ARTICLE{'ref_categorie'},$ARTICLE{'article_lieu'},$ARTICLE{'quantity'})=$c->fetchrow()) {
	#$string .= " <label>&nbsp;&nbsp;$ARTICLE{'genre'}</label>";
	my $img;
	if ($ARTICLE{'pochette'} eq '') {$ARTICLE{'pochette'} = "../images/blank.gif";}	
	if ($ARTICLE{'date'} eq $date) {$img = "../images/new_article.gif"}else {}
	my $add3;
	if ($ARTICLE{'ref_categorie'} eq '11') {$add3 = $ARTICLE{'article_lieu'};}
	$string .= "<td align=\"left\" width=\"253px\" height=\"100px\" style=\"background-image:url(../images/table_article_decoration.jpg);background-position:right bottom;background-repeat: no-repeat;\">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&amp;action=detailother&amp;article=$ARTICLE{'id_article'}\" class=\"menulink3\" >$ARTICLE{'name'} $add3</a><br/>&nbsp;&nbsp;&nbsp;&nbsp;<img alt=\"\" src=\"$ARTICLE{'pochette'}\" /> <img alt=\"\" src=\"$img\" /><br/>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$ARTICLE{'price'} <br/><br/></td>";
	$i += 1;$j += 1;
	if ($i eq 1) {$string .= "<td align=\"left\" width=\"10px\"></td>";$i = 0;}	
	if ($j eq 2) {$string .= "</tr><tr>";$j = 0;}
    }    
    $string .= "</tr></table>";
    return $string;
    
}

sub loadViewArticleFromShopIndex {
    my $lang = $query->param("lang");
    my  $cat = shift || '';
    my  $type = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d",$hour);
    my  $depot = $query->param("depot");
    $depot =~ s/[^A-Za-z0-9 ]//;
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  $add;
    $date = trimwhitespace($date);
    $time = trimwhitespace($time);
    if ($time eq '0' or $time eq '1' or $time eq '2' or $time eq '3' or $time eq '4' or $time eq '5' or $time eq '6' or $time eq '7' or $time eq '8' or $time eq '9') {
	$time = "0" .$time;
    }

    my  $add2;
    my  $dep;
    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");

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
	$add .= getAdd();
    

    my  ($c)= sqlSelect("count(article.nom)",
			   "article",
			   "enchere_date_fin > '$date%' AND ref_statut = '3' and enchere = 0 $add and quantite > 0");	
	

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
	$string .= "<a href=\"/cgi-bin/recordz.cgi?page=main&lang=$lang&amp;session=$session_id&amp;min_index_last_hour=$min_index&amp;max_index_last_hour=$max_index&amp;country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=$with_lang_french&amp;with_lang_german=$with_lang_german&amp;with_lang_italian=$with_lang_italian&amp;with_lang_english=$with_lang_english\"  class=\"menulink2\" ><-$j-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }
    if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }        
return $string;    
}
sub viewArticleOnlyEnchShopIndex {
    
    my  $cat = shift || '';
    my  $type = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d",$hour);
    my  $depot = $query->param("depot");
    $depot =~ s/[^A-Za-z0-9 ]//;
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  $add;
    $date = trimwhitespace($date);
    $time = trimwhitespace($time);
    if ($time eq '0' or $time eq '1' or $time eq '2' or $time eq '3' or $time eq '4' or $time eq '5' or $time eq '6' or $time eq '7' or $time eq '8' or $time eq '9') {
	$time = "0" .$time;
    }

    my  $add2;
    my  $dep;
    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");

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
	$add .= getAdd();
    

    my  ($c)= sqlSelect("count(article.nom)",
			   "article",
			   "enchere_date_fin > '$date%' AND ref_statut = '3' and enchere = 1 $add");	
	

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
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&amp;min_index_last_hour=$min_index&amp;max_index_last_hour=$max_index&amp;country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=$with_lang_french&amp;with_lang_german=$with_lang_german&amp;with_lang_italian=$with_lang_italian&amp;with_lang_english=$with_lang_english&saw=onlyench\"  class=\"menulink2\" ><-$j-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }
    if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }        
return $string;    
}

sub loadLingerieIndex {
    $lang = $query->param("lang") ;		
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
    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");
    my  $add2;
    
    my $ref_cat;
    my $ref_subcat;
    if ($category) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $add .= " AND article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
    }
    if ($subcat) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcat' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $add .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
    if ($add eq "") {
	$add .= " AND article.ref_categorie = 21 or article.ref_categorie = 31";
    }	

    my  ($c)= $db->sqlSelect("count(id_article)",
			   "article,met_en_vente, categorie_libelle_langue $from",
			   "ref_article = id_article AND ref_statut = '3' AND  enchere_date_fin > '$date% ' AND quantite > 0 $add $add2");	
	
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
	$string .= "<a href=\"/cgi-bin/d.pl?lang=$lang&amp;page=lingerie&amp;session=$session_id&amp;min_index=$min_index&amp;max_index=$max_index&amp;country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=with_lang_french&amp;with_lang_italian=$with_lang_italian&amp;with_lang_german=with_lang_german&amp;with_lang_english=$with_lang_english\"  ><-$j-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }
    if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }        
return $string;    
 
}

sub loadAutomobileIndex {
    $lang = $query->param("lang") ;		
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
    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");
    my  $add2;
    
    my $ref_cat;
    my $ref_subcat;
    if ($category) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $add .= " AND article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
    }
    if ($subcat) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcat' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $add .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
	
    if ($add eq "") {
	$add2 .= " AND article.ref_categorie = 5 AND article.ref_categorie = categorie_libelle_langue.ref_categorie";
    }	

    my  ($c)= $db->sqlSelect("count(id_article)",
			   "article,met_en_vente, categorie_libelle_langue $from",
			   "ref_article = id_article AND ref_statut = '3' AND  enchere_date_fin > '$date% ' AND quantite > 0 $add $add2");	
	
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
	$string .= "<a href=\"/cgi-bin/i.pl?lang=$lang&amp;page=auto&amp;session=$session_id&amp;min_index=$min_index&amp;max_index=$max_index&amp;country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=with_lang_french&amp;with_lang_italian=$with_lang_italian&amp;with_lang_german=with_lang_german&amp;with_lang_english=$with_lang_english&subcat=$subcat\"  ><-$j-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }
    if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }        
return $string;    
 
}

sub loadMotoindex {
    $lang = $query->param("lang") ;		
    my  $cat = shift || '';
    my  $type = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $depot = $query->param("depot");
    $depot =~ s/[^A-Za-z0-9 ]//;
    my $category = $query->param("category");
    my $subcat = $query->param("subcategory");
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  $add;
    my $from;
    my $fabricant = $query->param("fabricant");
    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");
    my  $add2;
    
    my $ref_cat;
    my $ref_subcat;
    if ($category) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $add .= " AND article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
    }
    if ($subcat) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcat' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $add .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
	
    if ($add eq "") {
	$add2 .= " AND article.ref_subcategorie between 58 and 67 AND subcategorie_libelle_langue.ref_subcategorie = article.ref_subcategorie AND article.ref_categorie = categorie_libelle_langue.ref_categorie";
    }	

    my  ($c)= $db->sqlSelect("count(id_article)",
			   "article,met_en_vente, categorie_libelle_langue,subcategorie_libelle_langue $from",
			   "ref_article = id_article AND ref_statut = '3' AND  enchere_date_fin > '$date% ' AND quantite > 0 $add $add2");	
	

	my $total = $c;
    my $nb_page = 0;		
	
	my $first_page = 0;
	my $count_per_page = 40;
	my $counter = ($total / $count_per_page); #Should be get from db;
	my $min_index = $query->param("min_index");
    my $next_page = $query->param("next_page");
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
	$string .= "<a href=\"/cgi-bin/j.pl?fabricant=$fabricant&amp;action=dosearchcar&amp;subcat=$subcat&category=$category&amp;min_index=0&amp;max_index=40&amp;index_page=$index_page&amp;page=moto&amp;lang=$lang&amp;page=main&amp;session=$session_id&amp;min_index_our_selection=0&amp;max_index_our_selection=40&amp;min_inde=$min_index&amp;max_index=$max_index&amp;categories=$category\" ><-First page-></a>&#160;&nbsp;";				
	
	if (($index_page -1) > 0) {
		$previous_page = $previous_page - 1;
		$index_page--;
		$index--;
		$min_index = $min_index -40;
		$max_index = $max_index -40;
		$string .= "<a href=\"/cgi-bin/j.pl?fabricant=$fabricant&amp;action=dosearchcar&amp;subcat=$subcat&amp;category=$category&amp;lang=$lang&amp;page=moto&amp;session=$session_id&amp;min_index_our_selection=$min_index&amp;max_index_our_selection=$max_index&amp;previous_page=$previous_page&amp;index_page=$index_page&amp;previous_page=$previous_page&amp;min_index=$min_index&amp;max_index=$max_index&amp;categories=$category\" ><-Previous-></a>&#160;&nbsp;";				
	}
	for my $index ($min_index..$counter) {						
		$next_page = $min_index + 40;
		if ($index_page < $count_per_page) {
			if (($index_page % $count_per_page) > 0) {							
				$string .= "<a href=\"/cgi-bin/j.pl?fabricant=$fabricant&amp;action=dosearchcar&amp;subcat=$subcat&amp;category=$category&amp;lang=$lang&amp;page=moto&amp;session=$session_id&amp;min_index_our_selection=$min_index&amp;max_index_our_selection=$max_index&amp;previous_page=$previous_page&amp;index_page=$index_page&amp;previous_page=$previous_page&amp;index_page=$index_page&amp;min_index=$min_index&amp;max_index=$max_index&amp;categories=$category\" ><-$index_page-></a>&#160;&nbsp;";								

			}
		}		
		$index_page++;
		$index++;
		$counter--;
		$min_index += 40;;						
		$max_index += 40;;					
	}	
	$string .= "<a href=\"/cgi-bin/j.pl?fabricant=$fabricant&amp;action=dosearchcar&amp;subcat=$subcat&amp;category=$category&amp;lang=$lang&amp;page=moto&amp;session=$session_id&amp;min_index_our_selection=$min_index&amp;max_index_our_selection=$max_index&amp;min_index=$min_index&amp;max_index=$max_index&amp;previous_page=$previous_page&amp;next_page=$next_page&amp;categories=$category\" ><-Next-></a>&#160;&nbsp;";				      
	return $string;
}

sub loadLingerieByIndex {
	loadLanguage();
    $lang = $query->param("lang") ;		
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
    my  $add = "";
    my $from;
    my  $add2;
    my $ref_cat;
    my $ref_subcat;

    if ($category) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $add .= " AND article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
    }
    if ($subcat) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcat' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $add .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
	
    if ($add eq "") {
	$add .= " AND article.ref_categorie = 21 or article.ref_categorie = 31";
    }	
    
    if (!$index_start ) {$index_start = 0;}
    if (!$index_end ) {$index_end = 40;}

   

    my  ($c)= $db->sqlSelectMany("DISTINCT(article.nom),id_article,marque,prix, categorie_libelle_langue.ref_categorie,pochette ",
		       "met_en_vente, article, categorie_libelle_langue, libelle, langue $from",
		       "ref_article = id_article and article.ref_categorie = categorie_libelle_langue.ref_categorie AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND met_en_vente.page_categorie = 'on' AND ref_statut = '3'  AND  article.ref_categorie = categorie_libelle_langue.ref_categorie AND enchere_date_fin > "." '$date%'  $add $add2 ORDER BY  date_stock DESC LIMIT $index_start, $index_end");	   my $i = 0;my $j = 0;
    my $string = "<table style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><tr style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"151\">$SERVER{'article_name_label'}</td><td align=\"left\">$SERVER{'fabricant'}</a></td><td align=\"left\">$SERVER{'article_price_label'}</td></tr>";
    

    
    
    while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'author'},$ARTICLE{'price'},$ARTICLE{'ref_categorie'},$ARTICLE{'image'})=$c->fetchrow()) {
	if ($ARTICLE{'image'} eq '') {
		##$ARTICLE{'image'} = "../images/blank.gif";
	}
        if ($ARTICLE{'ref_categorie'}) {
            $ARTICLE{'genre'} = $db->sqlSelect ("libelle.libelle","categorie_libelle_langue, libelle, langue","categorie_libelle_langue.ref_categorie = '$ARTICLE{'ref_categorie'}' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
        }
        
	$string .= "<tr><td align=\"left\"><img alt=\"\"  src=\"$ARTICLE{'image'}\"></td><td align=\"left\"><a href=\"/cgi-bin/detail.pl?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'author'}</td><td align=\"left\">$ARTICLE{'price'}</td></tr>";
    }
    $string .="</table>";    
    return $string;
      
}
sub loadMotoByIndex {
    loadLanguage();
    $lang = $query->param("lang") ;		
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
    my  $add = "";
    my $from;
    my  $add2;
    my $ref_cat;
    my $ref_subcat;

    if ($category) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $add .= " AND article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
    }
    if ($subcat) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcat' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $add .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
	
    if ($add eq "") {
	$add2 .= " AND article.ref_subcategorie between 58 and 67";
	
    }	
    
    if (!$index_start ) {$index_start = 0;}
    if (!$index_end ) {$index_end = 40;}

   

        my  ($c)= $db->sqlSelectMany("article.nom,id_article,marque,prix, categorie_libelle_langue.ref_categorie,pochette ",
		       "article,met_en_vente,categorie_libelle_langue, subcategorie_libelle_langue",
		       "ref_article = id_article  AND met_en_vente.notre_selection = '1'  AND ref_statut = '3' AND article.quantite > 0 and article.enchere_date_fin > '$date $time' AND categorie_libelle_langue.ref_categorie = article.ref_categorie AND subcategorie_libelle_langue.ref_subcategorie = article.ref_subcategorie $add  $add2 ORDER BY id_article DESC LIMIT $index_start, $index_end");	
    my $i = 0;my $j = 0;
   $string = "<table style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><tr style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"151\">$SERVER{'article_name_label'}</td><td align=\"left\">$SERVER{'fabricant'}</a></td><td align=\"left\">$SERVER{'article_price_label'}</td></tr>";

    
      while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'author'},$ARTICLE{'price'},$ARTICLE{'ref_categorie'},$ARTICLE{'image'})=$c->fetchrow()) {
	if ($ARTICLE{'image'} eq '') {
		##$ARTICLE{'image'} = "../images/blank.gif";
	}
        if ($ARTICLE{'ref_categorie'}) {
            $ARTICLE{'genre'} = $db->sqlSelect ("libelle.libelle","categorie_libelle_langue, libelle, langue","categorie_libelle_langue.ref_categorie = '$ARTICLE{'ref_categorie'}' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
        }
        
	$string .= "<tr><td align=\"left\"><img alt=\"\"  src=\"$ARTICLE{'image'}\"></td><td align=\"left\"><a href=\"/cgi-bin/detail.pl?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'author'}</td><td align=\"left\">$ARTICLE{'price'}</td></tr>";
    }
    $string .="</table>";    
    return $string;
  
}
sub loadAutomobileByIndex {
	loadLanguage();
    $lang = $query->param("lang") ;	
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
    my  $add = "";
    my $from;
    my  $add2;
    my $ref_cat;
    my $ref_subcat;

    if ($category) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $add .= " AND article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
    }
    if ($subcat) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcat' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $add .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat AND subcategorie_libelle_langue.ref_subcategorie = article.ref_subcategorie";
	    $from .= ", subcategorie_libelle_langue";
    }
	
    if ($add eq "") {
	$add2 .= " AND article.ref_categorie = 5 and categorie_libelle_langue.ref_categorie = article.ref_categorie";
    }	
    
    if (!$index_start ) {$index_start = 0;}
    if (!$index_end ) {$index_end = 40;}

   

            my  ($c)= $db->sqlSelectMany("DISTINCT article.nom,id_article,marque,prix, categorie_libelle_langue.ref_categorie,pochette ",
		       "article,met_en_vente,categorie_libelle_langue $from",
		       "ref_article = id_article AND ref_statut = '3' and quantite > 0 AND  enchere_date_fin > "." '$date%'  AND article.ref_categorie = 5 AND categorie_libelle_langue.ref_categorie = article.ref_categorie $add $add2 ORDER BY  date_stock DESC LIMIT $index_start, $index_end  ");	    
    my $i = 0;my $j = 0;
    $string = "<table style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><tr style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"151\">$SERVER{'article_name_label'}</td><td align=\"left\">$SERVER{'fabricant'}</a></td><td align=\"left\">$SERVER{'article_price_label'}</td></tr>";

    
      while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'author'},$ARTICLE{'price'},$ARTICLE{'ref_categorie'},$ARTICLE{'image'})=$c->fetchrow()) {
	if ($ARTICLE{'image'} eq '') {
		##$ARTICLE{'image'} = "../images/blank.gif";
	}
        if ($ARTICLE{'ref_categorie'}) {
            $ARTICLE{'genre'} = $db->sqlSelect ("libelle.libelle","categorie_libelle_langue, libelle, langue","categorie_libelle_langue.ref_categorie = '$ARTICLE{'ref_categorie'}' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
        }
        
	$string .= "<tr><td align=\"left\"><img alt=\"\"  src=\"$ARTICLE{'image'}\"></td><td align=\"left\"><a href=\"/cgi-bin/detail.pl?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'author'}</td><td align=\"left\">$ARTICLE{'price'}</td></tr>";
    }
    $string .="</table>";    
    return $string;
    
}


sub loadArtAndDesignIndex {
    my $ref_cat;
    my $ref_subcat;
    my $lang = $query->param("lang") ;	
    my  $category = $query->param("category");
    my  $subcat = $query->param("subcat");
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
	my $from = '';
    $from .= ", categorie_libelle_langue";
    my $nb_page  = '0';
    if (!$category) {
        my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $add .= " AND article.ref_categorie = 0 AND categorie_libelle_langue.ref_categorie = 0 and  article.ref_categorie = 0";
    }
    if ($subcat) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcat' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $add .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
    my $country_swiss = $query->param("country_swiss"); my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french"); my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian"); my $with_lang_english = $query->param("with_lang_english");

    my  ($c)= $db->sqlSelect("count(id_article)","article,met_en_vente $from","ref_article = id_article AND ref_statut = '3' AND  enchere_date_fin > '$date% ' AND quantite > 0 $add AND article.ref_categorie = 55");		
    my $counter = $c;
	my $total = $c;
		
	
	my $first_page = 0;
	my $count_per_page = 40;
	my $counter = ($total / $count_per_page); #Should be get from db;
	my $min_index = $query->param("min_index");
    my $next_page = $query->param("next_page");
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
	                    #http://localhost/cgi-bin/a.pl?lang=fr&page=art_design&u=&session=&category=Art%20et%20design&subcat=Peintures
		$string .= "<a href=\"/cgi-bin/a.pl?subcat=$subcat&category=$category&amp;min_index=0&amp;max_index=40&amp;index_page=$index_page&amp;page=art_design&&amp;lang=$lang&amp;page=main&amp;session=$session_id&amp;min_index_our_selection=0&amp;max_index_our_selection=40\" ><-First page-></a>&#160;&nbsp;";				
	
	if (($index_page -1) > 0) {
		$previous_page = $previous_page - 1;
		$index_page--;
		$index--;
		$min_index = $min_index -40;
		$max_index = $max_index -40;
		$string .= "<a href=\"/cgi-bin/a.pl?subcat=$subcat&amp;category=$category&amp;lang=$lang&amp;page=art_design&amp;session=$session_id&amp;min_index_our_selection=$min_index&amp;max_index_our_selection=$max_index&amp;previous_page=$previous_page&amp;index_page=$index_page&amp;previous_page=$previous_page\" ><-Previous-></a>&#160;&nbsp;";				
	}
	for my $index ($min_index..$counter) {						
		$next_page = $min_index + 40;
		if ($index_page < $count_per_page) {
			if (($index_page % $count_per_page) > 0) {							
				$string .= "<a href=\"/cgi-bin/a.pl?subcat=$subcat&amp;category=$category&amp;lang=$lang&amp;page=art_design&&amp;session=$session_id&amp;min_index_our_selection=$min_index&amp;max_index_our_selection=$max_index&amp;previous_page=$previous_page&amp;index_page=$index_page&amp;previous_page=$previous_page&amp;index_page=$index_page\"\" ><-$index_page-></a>&#160;&nbsp;";								

			}
		}		
		$index_page++;
		$index++;
		$counter--;
		$min_index += 40;;						
		$max_index += 40;;					
	}	
	$string .= "<a href=\"/cgi-bin/a.pl?lsubcat=$subcat&amp;category=$category&amp;lang=$lang&amp;page=art_design&amp;session=$session_id&amp;min_index_our_selection=$min_index&amp;max_index_our_selection=$max_index&amp;min_index=$min_index&amp;max_index=$max_index&amp;previous_page=$previous_page&amp;next_page=$next_page\" ><-Next-></a>&#160;&nbsp;";				      
    return $string;    
}

sub loadArtAndDesignByIndex {
	loadLanguage();
    $lang = $query->param("lang") ;		
    my  $cat = shift || '';my  $type = shift  || '';my  $depot = $query->param("depot") ;$depot=~ s/[^A-Za-z0-9 ]//;
    my  $index_start = $query->param ("min_index");$index_start=~ s/[^A-Za-z0-9 ]//;my  $index_end = $query->param ("max_index");$index_end =~ s/[^A-Za-z0-9 ]//;
    my $category = $query->param("category");my $subcat = $query->param("subcat");my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    $date = trimwhitespace($date);my  $string = "";my  $add;my $from;
    my $ref_cat;
    my $ref_subcat;
    $from .= ", categorie_libelle_langue";
    if (!$category) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $add .= " AND article.ref_categorie = 0 AND categorie_libelle_langue.ref_categorie = 0 and  article.ref_categorie = 0 and categorie_libelle_langue.ref_categorie  = article.ref_categorie";
    } else {
	$add .= " AND article.ref_categorie = 0  and  article.ref_categorie = 0 and categorie_libelle_langue.ref_categorie  = article.ref_categorie";
    }
    
    if ($subcat) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcat' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $add .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
    if (!$index_start ) {$index_start = 0;}if (!$index_end ) {$index_end = 40;};
    my  ($c)= $db->sqlSelectMany("DISTINCT(article.nom),id_article,marque,prix, categorie_libelle_langue.ref_categorie,pochette","article,met_en_vente $from","ref_article = id_article  AND ref_statut = '3' and quantite > 0 AND  enchere_date_fin > "." '$date%' AND article.ref_categorie = 0 $add ORDER BY  date_stock DESC LIMIT $index_start, $index_end  ");	    
    my $i = 0;my $j = 0;
	$string = "<table style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><tr style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"151\">$SERVER{'article_name_label'}</td><td align=\"left\">$SERVER{'fabricant'}</a></td><td align=\"left\">$SERVER{'article_price_label'}</td></tr>";
    while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'author'},$ARTICLE{'price'},$ARTICLE{'ref_categorie'},$ARTICLE{'image'})=$c->fetchrow()) {
	if ($ARTICLE{'image'} eq '') {
		##$ARTICLE{'image'} = "../images/blank.gif";
	}
        if ($ARTICLE{'ref_categorie'}) {
            $ARTICLE{'genre'} = $db->sqlSelect ("libelle.libelle","categorie_libelle_langue, libelle, langue","categorie_libelle_langue.ref_categorie = '$ARTICLE{'ref_categorie'}' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
        }
        
	$string .= "<tr><td align=\"left\"><img alt=\"\"  src=\"$ARTICLE{'image'}\"></td><td align=\"left\"><a href=\"/cgi-bin/detail.pl?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'author'}</td><td align=\"left\">$ARTICLE{'price'}</td></tr>";
    }
    $string .="</table>";    
    return $string;
  
}

sub loadInstrumentIndex {
    $lang = $query->param("lang") ;		
    my  $cat = shift || '';
    my  $type = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $category = $query->param("subcat");

    
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  $add;my $from;
    if ($category) {
	$from .= "subcategorie_$lang,categorie_$lang";
	$add .= " subcategorie_$lang.nom = '$category' AND article.ref_subcategorie = id_subcategorie";
    }
    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");

my  ($c)= sqlSelect("count(id_article)","article,met_en_vente $from","ref_article = id_article AND ref_statut = '3' AND  enchere_date_fin > '$date% ' AND quantite > 0 $add AND article.ref_categorie = 42");		
    my  $nb_page = arrondi ($c / 40, 1);
    my  $min_index = '0';my  $max_index = '40';    
    for (my  $i = '0'; $i < $nb_page;$i++) {		
	my $j;
	if ($i <= 9) {$j = "0$i";}else {$j = $i;}
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=instruments&amp;session=$session_id&amp;min_index=$min_index&amp;max_index=$max_index&country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=with_lang_french&with_lang_italian=$with_lang_italian&amp;with_lang_german=with_lang_german&with_lang_english=$with_lang_english&category=$category\"  class=\"menulink2\" ><-$j-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }
      if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }
      return $string;
}

sub loadInstrumentByIndex {
    $lang = $query->param("lang") ;	    
    my  $cat = shift || '';my  $type = shift  || '';my  $depot = $query->param("depot") ;$depot=~ s/[^A-Za-z0-9 ]//;
    my  $index_start = $query->param ("min_index");$index_start=~ s/[^A-Za-z0-9 ]//;my  $index_end = $query->param ("max_index");$index_end =~ s/[^A-Za-z0-9 ]//;
    my $category = $query->param("subcat");my $subcat = $query->param("category");my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    $date = trimwhitespace($date);my  $string = "";my  $add;my $from;
    if ($subcat) {
	$from .= ",subcategorie_$lang";
	$add .= " AND subcategorie_$lang.nom = '$subcat' AND article.ref_subcategorie = id_subcategorie";
    }
    #if ($subcat) {$from .= ",subcategorie_$lang";$add .= " AND subcategorie_$lang.nom = '$subcat' AND article.ref_subcategorie = id_subcategorie";}    
    if (!$index_start ) {$index_start = 0;}if (!$index_end ) {$index_end = 40;}$add .= getAdd();    
    my  ($c)= sqlSelectMany("DISTINCT article.nom,marque,prix, pochette,id_article,date_stock,article.ref_categorie,article.lieu,quantite","article,met_en_vente $from","ref_article = id_article  AND ref_statut = '3' and quantite > 0 AND  enchere_date_fin > "." '$date%' AND article.ref_categorie = 42 $add ORDER BY  date_stock DESC LIMIT $index_start, $index_end  ");	    
    my $i = 0;my $j = 0;
    $string .= "<table style=\"border-top-width:medium;border-top-color:#94CEFA\"><tr>";
    while( ($ARTICLE{'name'},$ARTICLE{'author'},$ARTICLE{'price'},$ARTICLE{'pochette'},$ARTICLE{'id_article'},$ARTICLE{'date'},$ARTICLE{'ref_categorie'},$ARTICLE{'article_lieu'},$ARTICLE{'quantity'})=$c->fetchrow()) {
	my $img;
	if ($ARTICLE{'pochette'} eq '') {$ARTICLE{'pochette'} = "../images/no.gif";}	
	if ($ARTICLE{'date'} eq $date) {$img = "../images/new_article.gif"}else {}
	my $add3;
	if ($ARTICLE{'ref_categorie'} eq '11') {$add3 = $ARTICLE{'article_lieu'};}
	$string .= "<td align=\"left\" width=\"253px\" height=\"100px\" style=\"background-image:url(../images/table_article_decoration.jpg);background-position:right bottom;background-repeat: no-repeat;\">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&amp;action=detailother&amp;article=$ARTICLE{'id_article'}\" class=\"menulink3\" >$ARTICLE{'name'} $add3</a><br/>&nbsp;&nbsp;&nbsp;&nbsp;<img alt=\"\" src=\"$ARTICLE{'pochette'}\" /> <img alt=\"\" src=\"$img\" /><br/>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$ARTICLE{'price'} <br/><br/></td>";
	$i += 1;$j += 1;
	if ($i eq 1) {$string .= "<td align=\"left\" width=\"10px\"></td>";$i = 0;}	
	if ($j eq 2) {$string .= "</tr><tr></tr><tr></tr><tr>";$j = 0;}
    }    
    $string .= "</table>";
    return $string;
      
}

sub loadHabitatJardinIndex {
    my  $cat = shift || '';my  $type = shift || '';my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $depot = $query->param("depot");  $depot =~ s/[^A-Za-z0-9 ]//;my $category = $query->param("category");my $subcat = $query->param("subcat");
    my  $string = "";my  $index = '0';my  $total = '0';my  $add;my $from;
    if ($category) {$from .= ",categorie_$lang";$add .= " AND categorie_$lang.nom = '$category' AND article.ref_categorie = id_categorie";}
    if ($subcat) {$from .= ",subcategorie_$lang";$add .= " AND subcategorie_$lang.nom = '$subcat' AND article.ref_subcategorie = id_subcategorie";}
    my $country_swiss = $query->param("country_swiss"); my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french"); my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian"); my $with_lang_english = $query->param("with_lang_english");

    my  ($c)= sqlSelect("count(id_article)","article,met_en_vente $from","ref_article = id_article AND ref_statut = '3' AND  enchere_date_fin > '$date% ' AND quantite > 0 $add AND article.ref_categorie BETWEEN 70 and 75");		
    my  $nb_page = arrondi ($c / 40, 1);
    my  $min_index = '0';my  $max_index = '40';    
    for (my  $i = '0'; $i < $nb_page;$i++) {		
	my $j;
	if ($i <= 9) {$j = "0$i";}else {$j = $i;}
	$string .= "<a href=\"/cgi-bin/h.pl?lang=$lang&amp;page=jardin&amp;session=$session_id&amp;min_index=$min_index&amp;max_index=$max_index&country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=with_lang_french&with_lang_italian=$with_lang_italian&amp;with_lang_german=with_lang_german&with_lang_english=$with_lang_english&subcat=$subcat&category=$category\"  class=\"menulink2\" ><-$j-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }
    if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }
    return $string;
}

sub loadHabitatJardinByIndex {
    my  $cat = shift || '';my  $type = shift  || '';my  $depot = $query->param("depot") ;$depot=~ s/[^A-Za-z0-9 ]//;
    my  $index_start = $query->param ("min_index");$index_start=~ s/[^A-Za-z0-9 ]//;my  $index_end = $query->param ("max_index");$index_end =~ s/[^A-Za-z0-9 ]//;
    my $category = $query->param("category");my $subcat = $query->param("subcat");my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    $date = trimwhitespace($date);my  $string = "";my  $add;my $from;
    if ($category) {$from .= ",categorie_$lang";$add .= " AND categorie_$lang.nom = '$category' AND article.ref_categorie = id_categorie";}
    if ($subcat) {$from .= ",subcategorie_$lang";$add .= " AND subcategorie_$lang.nom = '$subcat' AND article.ref_subcategorie = id_subcategorie";}    
    if (!$index_start ) {$index_start = 0;}if (!$index_end ) {$index_end = 40;}$add .= getAdd();    
    my  ($c)= sqlSelectMany("DISTINCT article.nom,marque,prix, pochette,id_article,date_stock,article.ref_categorie,article.lieu,quantite","article,met_en_vente $from","ref_article = id_article  AND ref_statut = '3' and quantite > 0 AND  enchere_date_fin > "." '$date%' AND article.ref_categorie BETWEEN 70 and 75  $add ORDER BY  date_stock DESC LIMIT $index_start, $index_end  ");	    
    my $i = 0;my $j = 0;
    $string .= "<table style=\"border-top-width:medium;border-top-color:#94CEFA\"><tr>";
    while( ($ARTICLE{'name'},$ARTICLE{'author'},$ARTICLE{'price'},$ARTICLE{'pochette'},$ARTICLE{'id_article'},$ARTICLE{'date'},$ARTICLE{'ref_categorie'},$ARTICLE{'article_lieu'},$ARTICLE{'quantity'})=$c->fetchrow()) {
	my $img;
	if ($ARTICLE{'pochette'} eq '') {$ARTICLE{'pochette'} = "../images/no.gif";}	
	if ($ARTICLE{'date'} eq $date) {$img = "../images/new_article.gif"}else {}
	my $add3;
	if ($ARTICLE{'ref_categorie'} eq '11') {$add3 = $ARTICLE{'article_lieu'};}
	$string .= "<td align=\"left\" width=\"253px\" height=\"100px\" style=\"background-image:url(../images/table_article_decoration.jpg);background-position:right bottom;background-repeat: no-repeat;\">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&amp;action=detailother&amp;article=$ARTICLE{'id_article'}\" class=\"menulink3\" >$ARTICLE{'name'} $add3</a><br/>&nbsp;&nbsp;&nbsp;&nbsp;<img alt=\"\" src=\"$ARTICLE{'pochette'}\" /> <img alt=\"\" src=\"$img\" /><br/>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$ARTICLE{'price'} <br/><br/></td>";
	$i += 1;$j += 1;
	if ($i eq 1) {$string .= "<td align=\"left\" width=\"10px\"></td>";$i = 0;}	
	if ($j eq 2) {$string .= "</tr><tr></tr><tr></tr><tr>";$j = 0;}
    }    
    $string .= "</table>";
    return $string;
}

sub loadCollectionIndex {
    $lang = $query->param("lang") ;		
    my  $cat = shift || '';
    my  $type = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $depot = $query->param("depot");
    $depot =~ s/[^A-Za-z0-9 ]//;
    my $category = $query->param("category");
    my $subcat = $query->param("subcategory");
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  $add;
    my $from;
    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");
    my  $add2;
    
    my $ref_cat;
    my $ref_subcat;
    if ($category) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $add .= " AND article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
    }
    if ($subcat) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcat' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $add .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
	
    if ($add eq "") {
	$add2 .= " AND article.ref_categorie = 18";
    }	

    my  ($c)= $db->sqlSelect("count(id_article)",
			   "article,met_en_vente, categorie_libelle_langue $from",
			   "ref_article = id_article AND ref_statut = '3' AND  enchere_date_fin > '$date% ' AND quantite > 0 $add $add2");	
	
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
	$string .= "<a href=\"/cgi-bin/n.pl?lang=$lang&amp;page=collection&amp;session=$session_id&amp;min_index=$min_index&amp;max_index=$max_index&amp;country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=with_lang_french&amp;with_lang_italian=$with_lang_italian&amp;with_lang_german=with_lang_german&amp;with_lang_english=$with_lang_english\" ><-$j-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }
  if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }        
return $string;    

}

sub loadCollectionByIndex {
    $lang = $query->param("lang") ;		
    my  $cat = shift || '';
    my  $type = shift  || '';
    my  $depot = $query->param("depot") ;
    $depot=~ s/[^A-Za-z0-9 ]//;
    my  $index_start = $query->param ("min_index");
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index");
    $index_end =~ s/[^A-Za-z0-9 ]//;
    my $category = $query->param("category");
    my $subcat = $query->param("subcategory");
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    $date = trimwhitespace($date);
    my  $string = "";
    my  $add = "";
    my $from;
    my  $add2;
    my $ref_cat;
    my $ref_subcat;
	loadLanguage();
    if ($category) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $add .= " AND article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
    }
    if ($subcat) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcat' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $add .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
	
    if ($add eq "") {
	$add2 .= " AND article.ref_categorie = 18";
    }	
    
    if (!$index_start ) {$index_start = 0;}
    if (!$index_end ) {$index_end = 40;}

   

        my  ($c)= $db->sqlSelectMany("article.nom,id_article,marque,prix, categorie_libelle_langue.ref_categorie,pochette ",
		       "article,met_en_vente,categorie_libelle_langue, subcategorie_libelle_langue",
		       "ref_article = id_article  AND met_en_vente.notre_selection = '1'  AND ref_statut = '3' AND article.quantite > 0 and article.enchere_date_fin > '$date $time' AND categorie_libelle_langue.ref_categorie = article.ref_categorie AND subcategorie_libelle_langue.ref_subcategorie = article.ref_subcategorie $add  $add2 ORDER BY id_article DESC LIMIT $index_start, $index_end");	

    my $i = 0;my $j = 0;
    $string = "<table style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><tr style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"151\">$SERVER{'article_name_label'}</td><td align=\"left\">$SERVER{'fabricant'}</a></td><td align=\"left\">$SERVER{'article_price_label'}</td></tr>";
    

	    while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'author'},$ARTICLE{'price'},$ARTICLE{'ref_categorie'},$ARTICLE{'image'})=$c->fetchrow()) {
	if ($ARTICLE{'image'} eq '') {
		##$ARTICLE{'image'} = "../images/blank.gif";
	}
        if ($ARTICLE{'ref_categorie'}) {
            $ARTICLE{'genre'} = $db->sqlSelect ("libelle.libelle","categorie_libelle_langue, libelle, langue","categorie_libelle_langue.ref_categorie = '$ARTICLE{'ref_categorie'}' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
        }
        
	$string .= "<tr><td align=\"left\"><img alt=\"\"  src=\"$ARTICLE{'image'}\"></td><td align=\"left\"><a href=\"/cgi-bin/detail.pl?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'author'}</td><td align=\"left\">$ARTICLE{'price'}</td></tr>";
    }
    $string .="</table>";    
    return $string;

}

sub loadCharityIndex {
    my  $cat = shift || '';my  $type = shift || '';my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);my  $depot = $query->param("depot");$depot =~ s/\W//g;my $category = $query->param("category");
    my $subcat = $query->param("subcat");my  $string = "";my  $index = '0';my  $total = '0';my  $add;    my $from;
    if ($category) {$from .= ",categorie_$lang";$add .= " AND categorie_$lang.nom = '$category' AND article.ref_categorie = id_categorie";    }
    if ($subcat) {$from .= ",subcategorie_$lang";$add .= " AND subcategorie_$lang.nom = '$subcat' AND article.ref_subcategorie = id_subcategorie";    }
    my $country_swiss = $query->param("country_swiss");my $country_france = $query->param("country_france");my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");my $with_lang_italian = $query->param("with_lang_italian");my $with_lang_english = $query->param("with_lang_english");
    my  ($c)= sqlSelect("count(id_article)","article,met_en_vente $from","ref_article = id_article AND ref_statut = '3' AND  enchere_date_fin > '$date% ' AND quantite > 0 $add AND article.ref_categorie 76");			
    my  $nb_page = arrondi ($c / 40, 1);my  $min_index = '0';my  $max_index = '40';    
    for (my  $i = '0'; $i < $nb_page;$i++) {my $j;if ($i <= 9) {$j = "0$i";}else {$j = $i;}
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=art_design&session=$session_id&amp;min_index=$min_index&amp;max_index=$max_index&country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=with_lang_french&with_lang_italian=$with_lang_italian&amp;with_lang_german=with_lang_german&with_lang_english=$with_lang_english\"  class=\"menulink2\" ><-$j-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }
  if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }
  
return $string;    
    
}

sub loadCharityByIndex {
    my  $cat = shift || '';my  $type = shift  || '';my  $depot = $query->param("depot") ;$depot=~ s/[^A-Za-z0-9 ]//;
    my  $index_start = $query->param ("min_index");$index_start=~ s/[^A-Za-z0-9 ]//;my  $index_end = $query->param ("max_index");$index_end =~ s/[^A-Za-z0-9 ]//;
    my $category = $query->param("category");my $subcat = $query->param("subcat");my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    $date = trimwhitespace($date);my  $string = "";my  $add;my $from;
    if ($category) {$from .= ",categorie_$lang";$add .= " AND categorie_$lang.nom = '$category' AND article.ref_categorie = id_categorie";}
    if ($subcat) {$from .= ",subcategorie_$lang";$add .= " AND subcategorie_$lang.nom = '$subcat' AND article.ref_subcategorie = id_subcategorie";}    
    if (!$index_start ) {$index_start = 0;}if (!$index_end ) {$index_end = 40;}$add .= getAdd();    
    my  ($c)= sqlSelectMany("DISTINCT article.nom,marque,prix, pochette,id_article,date_stock,article.ref_categorie,article.lieu,quantite","article,met_en_vente $from","ref_article = id_article  AND ref_statut = '3' and quantite > 0 AND  enchere_date_fin > "." '$date%' AND article.ref_categorie = 76 $add ORDER BY  date_stock DESC LIMIT $index_start, $index_end  ");	    
    my $i = 0;my $j = 0;
    $string .= "<table style=\"border-top-width:medium;border-top-color:#94CEFA\"><tr>";
    while( ($ARTICLE{'name'},$ARTICLE{'author'},$ARTICLE{'price'},$ARTICLE{'pochette'},$ARTICLE{'id_article'},$ARTICLE{'date'},$ARTICLE{'ref_categorie'},$ARTICLE{'article_lieu'},$ARTICLE{'quantity'})=$c->fetchrow()) {
	my $img;
	if ($ARTICLE{'pochette'} eq '') {$ARTICLE{'pochette'} = "../images/no.gif";}	
	if ($ARTICLE{'date'} eq $date) {$img = "../images/new_article.gif"}else {}
	my $add3;
	if ($ARTICLE{'ref_categorie'} eq '11') {$add3 = $ARTICLE{'article_lieu'};}
	$string .= "<td align=\"left\" width=\"253px\" height=\"100px\" style=\"background-image:url(../images/table_article_decoration.jpg);background-position:right bottom;background-repeat: no-repeat;\">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&amp;action=detailother&amp;article=$ARTICLE{'id_article'}\" class=\"menulink3\" >$ARTICLE{'name'} $add3</a><br/>&nbsp;&nbsp;&nbsp;&nbsp;<img alt=\"\" src=\"$ARTICLE{'pochette'}\" /> <img alt=\"\" src=\"$img\" /><br/>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$ARTICLE{'price'} <br/><br/></td>";
	$i += 1;$j += 1;
	if ($i eq 1) {$string .= "<td align=\"left\" width=\"10px\"></td>";$i = 0;}	
	if ($j eq 2) {$string .= "</tr><tr></tr><tr></tr><tr>";$j = 0;}
    }    
    $string .= "</table>";
    return $string;
    
}

sub loadBookIndex {
    $lang = $query->param("lang") ;		
    my  $cat = shift || '';
    my  $type = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $depot = $query->param("depot");
    $depot =~ s/[^A-Za-z0-9 ]//;
    my $category = $query->param("category");
    my $subcat = $query->param("subcategory");
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  $add;
    my $from;
    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");
    my  $add2;
    
    my $ref_cat;
    my $ref_subcat;
    if ($subcat) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcat' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $add .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
	
    if ($add eq "") {
	$add2 .= " AND article.ref_categorie = 9";
    }	

    my  ($c)= $db->sqlSelect("count(id_article)",
			   "article,met_en_vente, categorie_libelle_langue $from",
			   "ref_article = id_article AND ref_statut = '3' AND  enchere_date_fin > '$date% ' AND quantite > 0 $add $add2");	
	
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
	$string .= "<a href=\"/cgi-bin/s.pl?lang=$lang&amp;page=book&amp;session=$session_id&amp;min_index=$min_index&amp;max_index=$max_index&amp;country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=with_lang_french&amp;with_lang_italian=$with_lang_italian&amp;with_lang_german=with_lang_german&amp;with_lang_english=$with_lang_english\" ><-$j-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }
    if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }
    
return $string;    
    
}
sub loadBookByIndex {
	loadLanguage();
    $lang = $query->param("lang") ;		
    my  $cat = shift || '';
    my  $type = shift  || '';
    my  $depot = $query->param("depot") ;
    $depot=~ s/[^A-Za-z0-9 ]//;
    my  $index_start = $query->param ("min_index");
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index");
    $index_end =~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $string = "";
    my  $add;
    my $from;
    my $add2;
    my $category = $query->param("category");
    my $subcat = $query->param("subcategory");
    my $ref_cat;
    my $ref_subcat;
    if (!$index_start ) {$index_start = 0;}
    if (!$index_end ) {$index_end = 40;}
    if ($subcat) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcat' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $add .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
	
    if ($add eq "") {
	$add2 .= " AND (article.ref_categorie = 9)";
    }	
    
	my $i = 0;my $j = 0;
    $string = "<table style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><tr style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"151\">$SERVER{'article_name_label'}</td><td align=\"left\">$SERVER{'fabricant'}</a></td><td align=\"left\">$SERVER{'article_price_label'}</td></tr>";
            my  ($c)= $db->sqlSelectMany("article.nom,id_article,marque,prix, categorie_libelle_langue.ref_categorie,pochette ",
		       "article,met_en_vente,categorie_libelle_langue, subcategorie_libelle_langue",
		       "ref_article = id_article  AND met_en_vente.notre_selection = '1'  AND ref_statut = '3' AND article.quantite > 0 and article.enchere_date_fin > '$date' AND categorie_libelle_langue.ref_categorie = article.ref_categorie AND subcategorie_libelle_langue.ref_subcategorie = article.ref_subcategorie $add  $add2 ORDER BY id_article DESC LIMIT $index_start, $index_end");	

    while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'author'},$ARTICLE{'price'},$ARTICLE{'ref_categorie'},$ARTICLE{'image'})=$c->fetchrow()) {
	if ($ARTICLE{'image'} eq '') {
		##$ARTICLE{'image'} = "../images/blank.gif";
	}
        if ($ARTICLE{'ref_categorie'}) {
            $ARTICLE{'genre'} = $db->sqlSelect ("libelle.libelle","categorie_libelle_langue, libelle, langue","categorie_libelle_langue.ref_categorie = '$ARTICLE{'ref_categorie'}' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
        }
        
	$string .= "<tr><td align=\"left\"><img alt=\"\"  src=\"$ARTICLE{'image'}\"></td><td align=\"left\"><a href=\"/cgi-bin/detail.pl?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'author'}</td><td align=\"left\">$ARTICLE{'price'}</td></tr>";
    }
    $string .="</table>";    
    return $string;

}

sub loadBoatIndex {
    $lang = $query->param("lang") ;		
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
    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");
    my  $add2;
    
    my $ref_cat;
    my $ref_subcat;
    if ($subcat) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcat' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $add .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
	
    if ($add eq "") {
	$add2 .= " AND article.ref_categorie = 93";
    }	

    my  ($c)= $db->sqlSelect("count(id_article)",
			   "article,met_en_vente, categorie_libelle_langue $from",
			   "ref_article = id_article AND ref_statut = '3' AND  enchere_date_fin > '$date% ' AND quantite > 0 $add $add2");	
	
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
	$string .= "<a href=\"/cgi-bin/p.pl?lang=$lang&amp;page=boat&amp;session=$session_id&amp;min_index=$min_index&amp;max_index=$max_index&amp;country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=with_lang_french&amp;with_lang_italian=$with_lang_italian&amp;with_lang_german=with_lang_german&amp;with_lang_english=$with_lang_english\"  ><-$j-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }
  if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }        
return $string;    


}

sub loadBoatByIndex {
	loadLanguage();
    $lang = $query->param("lang") ;		
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
    my  $add = "";
    my $from;
    my  $add2;
    my $ref_cat;
    my $ref_subcat;

    if ($subcat) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcat' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $add .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
	
    if ($add eq "") {
	$add2 .= " AND article.ref_categorie = 94";
    }	
    
    if (!$index_start ) {$index_start = 0;}
    if (!$index_end ) {$index_end = 40;}

   

        my  ($c)= $db->sqlSelectMany("article.nom,id_article,marque,prix, categorie_libelle_langue.ref_categorie,pochette ",
		       "article,met_en_vente,categorie_libelle_langue, subcategorie_libelle_langue",
		       "ref_article = id_article  AND met_en_vente.notre_selection = '1'  AND ref_statut = '3' AND article.quantite > 0 and article.enchere_date_fin > '$date $time' AND categorie_libelle_langue.ref_categorie = article.ref_categorie AND subcategorie_libelle_langue.ref_subcategorie = article.ref_subcategorie $add  $add2 ORDER BY id_article DESC LIMIT $index_start, $index_end");	
    my $i = 0;my $j = 0;
    $string = "<table style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><tr style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"151\">$SERVER{'article_name_label'}</td><td align=\"left\">$SERVER{'fabricant'}</a></td><td align=\"left\">$SERVER{'article_price_label'}</td></tr>";
    
    while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'author'},$ARTICLE{'price'},$ARTICLE{'ref_categorie'},$ARTICLE{'image'})=$c->fetchrow()) {
	if ($ARTICLE{'image'} eq '') {
		##$ARTICLE{'image'} = "../images/blank.gif";
	}
        if ($ARTICLE{'ref_categorie'}) {
            $ARTICLE{'genre'} = $db->sqlSelect ("libelle.libelle","categorie_libelle_langue, libelle, langue","categorie_libelle_langue.ref_categorie = '$ARTICLE{'ref_categorie'}' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
        }
        
	$string .= "<tr><td align=\"left\"><img alt=\"\"  src=\"$ARTICLE{'image'}\"></td><td align=\"left\"><a href=\"/cgi-bin/detail.pl?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'author'}</td><td align=\"left\">$ARTICLE{'price'}</td></tr>";
    }
    $string .="</table>";    
    return $string;


}

sub loadChocolatIndex {
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
    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");
    
    if ($category) {
	$from .= ",subcategorie_libelle_langue";
	$add .= " AND article.ref_subcategorie = subcategorie_libelle_langue.ref_subcategorie = (SELECT subcategorie_libelle_langue.ref_subcategorie FROM subcategorie_libelle_langue, libelle, langue WHERE libelle.libelle = '$category' AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND libelle.key = '$lang')";
    }

    my  ($c)= sqlSelect("count(id_article)",
			   "article,met_en_vente $from",
			   "ref_article = id_article AND ref_statut = '3' AND  enchere_date_fin > '$date% ' AND quantite > 0 $add AND article.ref_categorie = 40");	
	
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
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=cigares&amp;session=$session_id&amp;min_index=$min_index&amp;max_index=$max_index&amp;country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=with_lang_french&amp;with_lang_italian=$with_lang_italian&amp;with_lang_german=with_lang_german&amp;with_lang_english=$with_lang_english\"  class=\"menulink2\" ><-$j-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }
    if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }        
return $string;    
}

sub loadChocolatByIndex {
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
    if ($category) {
	$from .= ",subcategorie_libelle_langue";
	$add .= " AND article.ref_subcategorie = subcategorie_libelle_langue.ref_subcategorie AND surcategorie_libelle_langue.ref_subcategorie = (SELECT subcategorie_libelle_langue.ref_subcategorie FROM subcategorie_libelle_langue, libelle, langue WHERE libelle.libelle = '$category' AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
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
		       "ref_article = id_article  AND ref_statut = '3' and quantite > 0 AND  enchere_date_fin > "." '$date%' AND article.ref_categorie = 40 $add ORDER BY  date_stock DESC LIMIT $index_start, $index_end  ");	
    
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
		$img = "../images/blank.gif"
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

sub loadParfumIndex {
    my $ref_cat;
    my $ref_subcat;
    my $lang = $query->param("lang") ;	
    my  $category = $query->param("category");
    my  $subcat = $query->param("subcat");
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
	my $from = '';
    $from .= ", categorie_libelle_langue";
    my $nb_page  = '0';
    if (!$category) {
        my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $add .= " AND article.ref_categorie = 0 AND categorie_libelle_langue.ref_categorie = 0 and  article.ref_categorie = 0";
    }
    if ($subcat) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcat' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $add .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
    my $country_swiss = $query->param("country_swiss"); my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french"); my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian"); my $with_lang_english = $query->param("with_lang_english");

    my  ($c)= $db->sqlSelect("count(id_article)","article,met_en_vente $from","ref_article = id_article AND ref_statut = '3' AND  enchere_date_fin > '$date% ' AND quantite > 0 $add AND article.ref_categorie = 55");		
    my $counter = $c;
	my $total = $c;
		
	
	my $first_page = 0;
	my $count_per_page = 40;
	my $counter = ($total / $count_per_page); #Should be get from db;
	my $min_index = $query->param("min_index");
    my $next_page = $query->param("next_page");
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
	                    #http://localhost/cgi-bin/b.pl?lang=fr&page=art_design&u=&session=&category=Art%20et%20design&subcat=Peintures
		$string .= "<a href=\"/cgi-bin/b.pl?subcat=$subcat&category=$category&amp;min_index=0&amp;max_index=40&amp;index_page=$index_page&amp;page=parfum&&amp;lang=$lang&amp;page=main&amp;session=$session_id&amp;min_index_our_selection=0&amp;max_index_our_selection=40\" ><-First page-></a>&#160;&nbsp;";				
	
	if (($index_page -1) > 0) {
		$previous_page = $previous_page - 1;
		$index_page--;
		$index--;
		$min_index = $min_index -40;
		$max_index = $max_index -40;
		$string .= "<a href=\"/cgi-bin/b.pl?subcat=$subcat&amp;category=$category&amp;lang=$lang&amp;page=parfum&amp;session=$session_id&amp;min_index_our_selection=$min_index&amp;max_index_our_selection=$max_index&amp;previous_page=$previous_page&amp;index_page=$index_page&amp;previous_page=$previous_page\" ><-Previous-></a>&#160;&nbsp;";				
	}
	for my $index ($min_index..$counter) {						
		$next_page = $min_index + 40;
		if ($index_page < $count_per_page) {
			if (($index_page % $count_per_page) > 0) {							
				$string .= "<a href=\"/cgi-bin/b.pl?subcat=$subcat&amp;category=$category&amp;lang=$lang&amp;page=parfum&&amp;session=$session_id&amp;min_index_our_selection=$min_index&amp;max_index_our_selection=$max_index&amp;previous_page=$previous_page&amp;index_page=$index_page&amp;previous_page=$previous_page&amp;index_page=$index_page\"\" ><-$index_page-></a>&#160;&nbsp;";								

			}
		}		
		$index_page++;
		$index++;
		$counter--;
		$min_index += 40;;						
		$max_index += 40;;					
	}	
	$string .= "<a href=\"/cgi-bin/b.pl?lsubcat=$subcat&amp;category=$category&amp;lang=$lang&amp;page=parfum&amp;session=$session_id&amp;min_index_our_selection=$min_index&amp;max_index_our_selection=$max_index&amp;min_index=$min_index&amp;max_index=$max_index&amp;previous_page=$previous_page&amp;next_page=$next_page\" ><-Next-></a>&#160;&nbsp;";				      
    return $string;    
    
}

sub loadParfumByIndex {
	loadLanguage();
    my  $cat = shift || '';
    my  $type = shift  || '';
    my  $depot = $query->param("depot") ;
    $depot=~ s/[^A-Za-z0-9 ]//;
    my  $index_start = $query->param ("min_index");
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index");
    $index_end =~ s/[^A-Za-z0-9 ]//;
    my $category = $query->param("category");
    my $subcat = $query->param("subcategory");
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    $date = trimwhitespace($date);
    my  $string = "";
    my  $add = "";
    my $from;
    my  $add2;
    my $ref_cat;
    my $ref_subcat;
	$lang = $query->param("lang");
    if ($category) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $add .= " AND article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
    }
    if ($subcat) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcat' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $add .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
	
    if ($add eq "") {
	$add2 .= " AND (article.ref_categorie = 13 or article.ref_categorie = 16) AND article.ref_categorie = categorie_libelle_langue.ref_categorie ";
    }	
    
    if (!$index_start ) {$index_start = 0;}
    if (!$index_end ) {$index_end = 40;}

   

    my  ($c)= $db->sqlSelectMany("DISTINCT(article.nom),id_article,marque,prix, categorie_libelle_langue.ref_categorie,pochette",
		       "article,met_en_vente,categorie_libelle_langue $from",
		       "ref_article = id_article  AND ref_statut = '3' and quantite > 0 AND  enchere_date_fin > "." '$date%'  $add $add2 ORDER BY  date_stock DESC LIMIT $index_start, $index_end  ");	    
    my $i = 0;my $j = 0;
	$string = "<table style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><tr style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"151\">$SERVER{'article_name_label'}</td><td align=\"left\">$SERVER{'fabricant'}</a></td><td align=\"left\">$SERVER{'article_price_label'}</td></tr>";

    
        while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'author'},$ARTICLE{'price'},$ARTICLE{'ref_categorie'},$ARTICLE{'image'})=$c->fetchrow()) {
	if ($ARTICLE{'image'} eq '') {
		##$ARTICLE{'image'} = "../images/blank.gif";
	}
        if ($ARTICLE{'ref_categorie'}) {
            $ARTICLE{'genre'} = $db->sqlSelect ("libelle.libelle","categorie_libelle_langue, libelle, langue","categorie_libelle_langue.ref_categorie = '$ARTICLE{'ref_categorie'}' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
        }
        
	$string .= "<tr><td align=\"left\"><img alt=\"\"  src=\"$ARTICLE{'image'}\"></td><td align=\"left\"><a href=\"/cgi-bin/detail.pl?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'author'}</td><td align=\"left\">$ARTICLE{'price'}</td></tr>";
    }
    $string .="</table>";    
    return $string;

}


sub loadGamesIndex {
	my  $lang = $query->param("lang");
    my  $cat = shift || '';
    my  $type = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $depot = $query->param("depot");
    my $category = $query->param("category");
    my $subcat = $query->param("subcat");
    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");

    
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my $from;
    my  $add;
    my  $add2;
    
    my $ref_cat;
    my $ref_subcat;
    if ($category) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $add .= " AND article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
    }
    if ($subcat) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcat' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $add .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
	
    if ($add eq "") {
	$add2 .= " AND (article.ref_categorie between 11 or article.ref_categorie = 95)";
    }	

    my  ($c)= $db->sqlSelect("count(id_article)",
			   "article,met_en_vente,categorie_libelle_langue $from",
			   "ref_article = id_article AND article.ref_categorie = categorie_libelle_langue.ref_categorie AND ref_statut = '3' AND  enchere_date_fin > '$date% ' $add ");	
	
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
	$string .= "<a href=\"/cgi-bin/r.pl ?lang=$lang&amp;page=games&session=$session_id&amp;min_index=$min_index&amp;max_index=$max_index&country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=with_lang_french&with_lang_italian=$with_lang_italian&amp;with_lang_german=with_lang_german&with_lang_english=$with_lang_english\"  ><-$j-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }
    if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }        
return $string;    
} 



sub loadCdVinylMixTapeIndex {
    $lang = $query->param("lang") ;		
    my  $cat = shift || '';
    my  $type = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $depot = $query->param("depot");
    my $category = $query->param("category");
    my $subcat = $query->param("subcat");
    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");

    
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my $from;
    my  $add;
    my  $add2;
    
    my $ref_cat;
    my $ref_subcat;
    if ($category) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $add .= " AND article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
    }
    if ($subcat) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcat' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $add .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
	
    if ($add eq "") {
	$add2 .= " AND article.ref_categorie between 39 and 41";
    }	

    my  ($c)= $db->sqlSelect("count(id_article)",
			   "article,met_en_vente,categorie_libelle_langue $from",
			   "ref_article = id_article AND article.ref_categorie = categorie_libelle_langue.ref_categorie AND ref_statut = '3' AND  enchere_date_fin > '$date% ' $add ");	
	
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
	$string .= "<a href=\"/cgi-bin/l.pl?lang=$lang&amp;page=cd_vinyl_mixtap&session=$session_id&amp;min_index=$min_index&amp;max_index=$max_index&country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=with_lang_french&with_lang_italian=$with_lang_italian&amp;with_lang_german=with_lang_german&with_lang_english=$with_lang_english\"  ><-$j-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }
    if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }        
return $string;    
}

sub loadCdVinylMixTapeByIndex {
	loadLanguage();
    $lang = $query->param("lang") ;		
    my  $cat = shift || '';
    my  $type = shift  || '';
    my  $depot = $query->param("depot") ;
    $depot=~ s/[^A-Za-z0-9 ]//;
    my  $index_start = $query->param ("min_index");
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index");
    $index_end =~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my $category = $query->param("category");
    my $subcat = $query->param("subcat");

    my  $string = "";
    my  $add;
    my  $add2;
    my  $dep;
    loadLanguage();
    if (!$index_start ) {
	$index_start = 0;
    }
    if (!$index_end ) {
	$index_end = 40;
    }
    my $from;
    my $ref_cat;
    my $ref_subcat;
    if ($category) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $add .= " AND article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
    }
    if ($subcat) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcat' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $add .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
	
    if ($add eq "") {
	$add2 .= " AND (article.ref_categorie between 39 and 41)";
    }	

        my  ($c)= $db->sqlSelectMany("article.nom,id_article,marque,prix, categorie_libelle_langue.ref_categorie,pochette ",
		       "article,met_en_vente,categorie_libelle_langue, subcategorie_libelle_langue",
		       "ref_article = id_article  AND met_en_vente.notre_selection = '1'  AND ref_statut = '3' AND article.quantite > 0 and article.enchere_date_fin > '$date $time' AND categorie_libelle_langue.ref_categorie = article.ref_categorie AND subcategorie_libelle_langue.ref_subcategorie = article.ref_subcategorie $add  $add2 ORDER BY id_article DESC LIMIT $index_start, $index_end");	
    my $i = 0;my $j = 0;
	$string = "<table style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><tr style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"151\">$SERVER{'article_name_label'}</td><td align=\"left\">$SERVER{'fabricant'}</a></td><td align=\"left\">$SERVER{'article_price_label'}</td></tr>";

    while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'author'},$ARTICLE{'price'},$ARTICLE{'ref_categorie'},$ARTICLE{'image'})=$c->fetchrow()) {

	if ($ARTICLE{'image'} eq '') {
		##$ARTICLE{'image'} = "../images/blank.gif";
	}
        if ($ARTICLE{'ref_categorie'}) {
            $ARTICLE{'genre'} = $db->sqlSelect ("libelle.libelle","categorie_libelle_langue, libelle, langue","categorie_libelle_langue.ref_categorie = '$ARTICLE{'ref_categorie'}' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
        }
        
	$string .= "<tr><td align=\"left\"><img alt=\"\"  src=\"$ARTICLE{'image'}\"></td><td align=\"left\"><a href=\"/cgi-bin/detail.pl?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'author'}</td><td align=\"left\">$ARTICLE{'price'}</td></tr>";
    }
    $string .="</table>";    
    return $string;

}

sub loadWineIndex {
    $lang = $query->param("lang") ;		
    my  $cat = shift || '';
    my  $type = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $depot = $query->param("depot");
    my $wine_country = $query->param("wine_country");
    my $wine_type = $query->param("wine_type");
    my $cepage = $query->param("cepage");
    my $subcat = $query->param("subcat");
    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");

    
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my $from;
    my  $add;
    my  $add2;
    my $ref_wine_type;
    my $ref_cat;
    my $ref_subcat;
    if ($wine_country) {
            my  @cat = $db->sqlSelect("id_pays_region_vin","pays_region_vin", "nom = '$wine_country'");
	    $ref_cat = $cat[0];
	    $add .= " AND article.ref_pays_region_vin = $ref_cat";
    }
    if ($cepage) {
            my  @sub_cat = $db->sqlSelect("ref_cepage","cepage","nom = '$cepage'");
	    $ref_subcat = $sub_cat[0];
	    $add .= " AND article.ref_cepage = $ref_subcat";
    }
	
    if ($wine_type) {
	    my @sub_wine_type = $db->sqlSelect("ref_type_de_vin","type_de_vin_libelle_langue,libelle,langue","libelle.libelle = '$wine_type' and type_de_vin_libelle_langue.ref_libelle = libelle.id_libelle and type_de_vin_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_wine_type = $sub_wine_type[0];
	    $add .=  " AND article.ref_type_de_vin = $ref_wine_type";
    }
    if ($add eq "") {
	$add2 .= " AND article.ref_categorie = 27";
    }	

    my  ($c)= $db->sqlSelect("count(id_article)",
			   "article,met_en_vente,categorie_libelle_langue $from",
			   "ref_article = id_article AND article.ref_categorie = categorie_libelle_langue.ref_categorie AND ref_statut = '3' AND  enchere_date_fin > '$date% ' $add ");	
	
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
	$string .= "<a href=\"/cgi-bin/o.pl?lang=$lang&amp;page=wine&session=$session_id&amp;min_index=$min_index&amp;max_index=$max_index\" ><-$j-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }
    if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }        
return $string;    

}

sub loadWineByIndex {
	loadLanguage();
    $lang = $query->param("lang") ;
	
    my  $cat = shift || '';
    my  $type = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $depot = $query->param("depot");
    my $wine_country = $query->param("country");
    my $wine_type = $query->param("wine_type");
    my $cepage = $query->param("cepage");
    my $subcat = $query->param("subcat");
    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");
    my  $index_start = $query->param ("min_index");
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index");
    $index_end =~ s/[^A-Za-z0-9 ]//;
    if (!$index_start ) {
	$index_start = 0;
    }
    if (!$index_end ) {
	$index_end = 40;
    }
    
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my $from;
    my  $add;
    my  $add2;
    my $ref_wine_type;
    my $ref_cat;
    my $ref_subcat;
    if ($wine_country) {
            my  @cat = $db->sqlSelect("id_pays_region_vin","pays_region_vin", "nom = '$wine_country'");
	    $ref_cat = $cat[0];
	    $add .= " AND article.ref_pays_region_vin = $ref_cat";
    }
    if ($cepage) {
            my  @sub_cat = $db->sqlSelect("ref_cepage","cepage","nom = '$cepage'");
	    $ref_subcat = $sub_cat[0];
	    $add .= " AND article.ref_cepage = $ref_subcat";
    }
	
    if ($wine_type) {
	    my @sub_wine_type = $db->sqlSelect("ref_type_de_vin","type_de_vin_libelle_langue,libelle,langue","libelle.libelle = '$wine_type' and type_de_vin_libelle_langue.ref_libelle = libelle.id_libelle and type_de_vin_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_wine_type = $sub_wine_type[0];
	    $add .=  " AND article.ref_type_de_vin = $ref_wine_type";
    }
    if ($add eq "") {
	$add2 .= " AND article.ref_categorie = 27";
    }
        my  ($c)= $db->sqlSelectMany("article.nom,id_article,marque,prix, categorie_libelle_langue.ref_categorie,pochette ",
		       "article,met_en_vente,categorie_libelle_langue, subcategorie_libelle_langue",
		       "ref_article = id_article  AND met_en_vente.notre_selection = '1'  AND ref_statut = '3' AND article.quantite > 0 and article.enchere_date_fin > '$date $time' AND categorie_libelle_langue.ref_categorie = article.ref_categorie AND subcategorie_libelle_langue.ref_subcategorie = article.ref_subcategorie $add  $add2 ORDER BY id_article DESC LIMIT $index_start, $index_end");	
    
    my $i = 0;my $j = 0;

    $string = "<table style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><tr style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"151\">$SERVER{'article_name_label'}</td><td align=\"left\">$SERVER{'fabricant'}</a></td><td align=\"left\">$SERVER{'article_price_label'}</td></tr>";

    while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'author'},$ARTICLE{'price'},$ARTICLE{'ref_categorie'},$ARTICLE{'image'})=$c->fetchrow()) {
	if ($ARTICLE{'image'} eq '') {
		##$ARTICLE{'image'} = "../images/blank.gif";
	}
        if ($ARTICLE{'ref_categorie'}) {
            $ARTICLE{'genre'} = $db->sqlSelect ("libelle.libelle","categorie_libelle_langue, libelle, langue","categorie_libelle_langue.ref_categorie = '$ARTICLE{'ref_categorie'}' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
        }
        
	$string .= "<tr><td align=\"left\"><img alt=\"\"  src=\"$ARTICLE{'image'}\"></td><td align=\"left\"><a href=\"/cgi-bin/detail.pl?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'author'}</td><td align=\"left\">$ARTICLE{'price'}</td></tr>";
    }
    $string .="</table>";    
    return $string;

}

sub loadTableIndexMyBuyToBuy {
    my $article = $query->param("article");
    my $username = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $depot = $query->param("depot");
    $depot =~ s/[^A-Za-z0-9 ]//;
    
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  ($c)= sqlSelectMany("distinct id_article",
			   "article,a_paye,personne",
			   "ref_article = id_article AND ref_acheteur = id_personne  AND nom_utilisateur = '$username' and a_paye.ref_statut = '8' and article.ref_condition_livraison <> 8 ");	
	
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
	$string .= "<a href=\"/cgi-bin/my_auctions.pllang=$lang&amp;session=$session_id&page=mybuy&option=mybuytobuy;&amp;min_index=$min_index&amp;max_index=$max_index\"  class=\"menulink2\" ><-$j-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }
    if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }        
return $string;    
}


sub loadTableByIndexMyBuyToBuy {

    my $username = shift || '';
    my  $index_start = $query->param ("min_index");
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index");
    $index_end =~ s/[^A-Za-z0-9 ]//;
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

    my  ($c)= sqlSelectMany("DISTINCT id_article,pochette,article.nom,montant,ref_vendeur,condition_payement_$lang.nom,condition_livraison_$lang.nom,a_paye.quantite,ref_condition_payement,a_paye.id_a_paye",
			   "article,personne,a_paye,condition_payement_$lang,condition_livraison_$lang",
			   "ref_article = id_article AND ref_acheteur = id_personne  AND nom_utilisateur = '$username' and a_paye.ref_statut = '8' AND ref_condition_payement = id_condition_payement AND  ref_condition_livraison  =  id_condition_livraison AND id_condition_livraison <> 8 LIMIT $index_start, $index_end");	
    

    my $i = 0;
    my $j = 0;
    $string = "<table style=\"border-width:thin; border-style:dotted; border-top-color:#94CEFA;border-right-color:#94CEFA;border-left-color:#94CEFA; border-bottom-color:#94CEFA\" width=\"555\" border=\"0\"><tr bgcolor=\"#DBE4F8\"><td align=\"left\" width=\"51\"</td><td align=\"left\" width=\"151\"</td><td align=\"left\"></td><td align=\"left\"></td><td align=\"left\"></td><td align=\"left\"></td><td align=\"left\">/td></tr>";
    while( ($ARTICLE{'id_article'},$ARTICLE{'pochette'}, $ARTICLE{'name'},$ARTICLE{'montant'},$ARTICLE{'ref_vendeur'},$ARTICLE{'payement_mode'},$ARTICLE{'deliver_mode'},$ARTICLE{'quantity'},$ARTICLE{'ref_condition_payement'},$ARTICLE{'id_a_paye'})=$c->fetchrow()) {
	#$string .= " <label>&nbsp;&nbsp;$ARTICLE{'genre'}</label>";
	my ($vendeur_username,$vendeur_name,$vendeur_firstname,$vendeur_adresse,$vendeur_city,$vendeur_npa)= sqlSelect("nom_utilisateur,nom,prenom,adresse,ville,npa", "personne","id_personne = '$ARTICLE{'ref_vendeur'}'");
	if ($ARTICLE{'pochette'} eq '') {$ARTICLE{'pochette'} = "../images/no.gif";}
	if ($ARTICLE{'ref_condition_payement'} ne 4) {	
	    $string .= "<tr><td align=\"left\"><img alt=\"\" src=\"$ARTICLE{'pochette'}\" alt=\"\"/></td><td align=\"left\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&amp;action=detailother&amp;article=$ARTICLE{'id_article'}\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'author'}<br/>$ARTICLE{'montant'}</td><td align=\"left\">$vendeur_username</td><td>$ARTICLE{'quantity'}</td></td><td align=\"left\">$ARTICLE{'payement_mode'}</td><td align=\"left\">$ARTICLE{'deliver_mode'}</td><td align=\"left\"><a href=\"javascript:void(0)\" class=\"menulink\"  onclick=\"window.open('/cgi-bin/update_statut_article_payed.pl?lang=$lang&amp;page=update_statut_article_payed&amp;session=$session_id&article=$ARTICLE{'id_article'}&id_a_paye=$ARTICLE{'id_a_paye'};','MyWindow','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=no,width=800,height=300,left=20,top=20')\">Update statut</a></td></tr>";
	}else {
	    $string .= "<tr><td align=\"left\"><img alt=\"\" src=\"$ARTICLE{'pochette'}\" alt=\"\"/></td><td align=\"left\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&amp;action=detailother&amp;article=$ARTICLE{'id_article'}\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'author'}<br/>$ARTICLE{'montant'}</td><td align=\"left\">$vendeur_username</td><td>$ARTICLE{'quantity'}</td></td><td align=\"left\">$ARTICLE{'payement_mode'}</td><td align=\"left\">$ARTICLE{'deliver_mode'}</td><td align=\"left\"><a href=\"javascript:void(0)\" class=\"menulink\"  onclick=\"window.open('/cgi-bin/update_statut_article_payed.pl?lang=$lang&amp;page=update_statut_article_paypayl&amp;session=$session_id&article=$ARTICLE{'id_article'}&price=$ARTICLE{'montant'}&name=$ARTICLE{'name'};','MyWindow','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=no,width=800,height=420,left=20,top=20')\">Paypal</a></td></tr>";	    
	}
	
    }
    $string .= "</table>";
    return $string;
        
}

sub loadTableByIndexDelivered {

    my $username = shift || '';
    my  $index_start = $query->param ("min_index");
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index");
    $index_end =~ s/[^A-Za-z0-9 ]//;
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

    my  ($c)= sqlSelectMany("DISTINCT id_article,pochette,article.nom,ref_vendeur,condition_payement_libelle_langue.ref_condition_payement,condition_livraison_libelle_langue.ref_condition_livraison,a_livre.quantite,date_reception",
			   "article,personne,a_livre,condition_payement_libelle_langue,condition_livraison_libelle_langue",
			   "ref_article = id_article AND ref_acheteur = id_personne  AND nom_utilisateur = '$username' and a_livre.ref_statut = '10' AND article.ref_condition_payement = condition_livraison_libelle_langue.ref_condition_payement AND article.ref_condition_livraison  =  condition_livraison_libelle_langue.ref_condition_livraison LIMIT $index_start, $index_end");	
    

    my $i = 0;
    my $j = 0;
    $string = "<table style=\"border-width:thin; border-style:dotted; border-top-color:#94CEFA;border-right-color:#94CEFA;border-left-color:#94CEFA; border-bottom-color:#94CEFA\" width=\"555\" border=\"0\"><tr bgcolor=\"#DBE4F8\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"151\">$SERVER{'article_name_label'}</td><td align=\"left\">Vendeur</td><td align=\"left\">$SERVER{'article_quantity_label'}</td><td>$SERVER{'date_reception'}</td></tr>";
    while( ($ARTICLE{'id_article'},$ARTICLE{'pochette'}, $ARTICLE{'name'},$ARTICLE{'ref_vendeur'},$ARTICLE{'payement_mode'},$ARTICLE{'deliver_mode'},$ARTICLE{'quantity'},$ARTICLE{'date_reception'})=$c->fetchrow()) {
	#$string .= " <label>&nbsp;&nbsp;$ARTICLE{'genre'}</label>";
	my ($vendeur_username,$vendeur_name,$vendeur_firstname,$vendeur_adresse,$vendeur_city,$vendeur_npa)= sqlSelect("nom_utilisateur,nom,prenom,adresse,ville,npa", "personne","id_personne = '$ARTICLE{'ref_vendeur'}'");
	if ($ARTICLE{'pochette'} eq '') {
		$ARTICLE{'pochette'} = "../images/no.gif";
	}
	$string .= "<tr><td align=\"left\"><img alt=\"\" src=\"$ARTICLE{'pochette'}\" alt=\"\"/></td><td align=\"left\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&amp;action=detailother&amp;article=$ARTICLE{'id_article'}\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$vendeur_username</td><td>$ARTICLE{'quantity'}</td><td>$ARTICLE{'date_reception'}</td><td align=\"left\"><a href=\"javascript:void(0)\" class=\"menulink\"  onclick=\"window.open('/cgi-bin/recordz.cgi?lang=$lang&amp;page=evalproduct&amp;session=$session_id&article=$ARTICLE{'id_article'}&buyer=$username;','MyWindow','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=no,width=800,height=300,left=20,top=20')\">Evaluez le produit</a></td></tr>";
	#$string .= "<td align=\"left\" width=\"300px\" style=\"border-style:dotted;border-width:thin;border-color:#94CEFA\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&amp;action=detailother&amp;article=$ARTICLE{'id_article'}\" class=\"menulink\" >$ARTICLE{'name'}</a><br/><img alt=\"\" src=\"$ARTICLE{'pochette'}\" alt=\"\"/><br/>$ARTICLE{'author'}<br/>$ARTICLE{'montant'} <br/>$ARTICLE{'date_stock'} Vendeur : $vendeur_username <br/>Pr�nom et nom : $vendeur_firstname $vendeur_name <br/>Ville : $vendeur_city<br /> Mode de payement : $ARTICLE{'payement_mode'}<br /> Livraison : $ARTICLE{'deliver_mode'} <br/><a href=\"javascript:void(0)\" class=\"menulink\"  onclick=\"window.open('/cgi-bin/recordz.cgi?lang=$lang&amp;page=evalproduct&amp;session=$session_id&article=$ARTICLE{'id_article'}&buyer=$username;','MyWindow','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=no,width=800,height=300,left=20,top=20')\">Evaluez le produit</a></td>";
	$i += 1;
	$j += 1;

	if ($i eq 1) {		
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



sub loadTableByIndexMyBuyToBuyWaiting {

    my $username = shift || '';
    my  $index_start = $query->param ("min_index");
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index");
    $index_end =~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);

    my  $string = "";
    my  $add;
    my  $add2;
    my  $dep;
    $string .= "<table style=\"border-width:thin; border-style:dotted; border-top-color:#94CEFA;border-right-color:#94CEFA;border-left-color:#94CEFA; border-bottom-color:#94CEFA\" width=\"555\" border=\"0\"><tr bgcolor=\"#DBE4F8\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"151\">$SERVER{'article_name_label'}</td><td align=\"left\">$SERVER{'article_price_label'}</td><td align=\"left\">Vendeur</td><td align=\"left\">Mode de payement : </td><td align=\"left\"> Livraison : </td><td align=\"left\"></td></tr>";
    if (!$index_start ) {
	$index_start = 0;
    }
    if (!$index_end ) {
	$index_end = 40;
    }
    
    my  ($c)= sqlSelectMany("pochette,article.nom,id_article,ref_vendeur,condition_payement_libelle_langue.ref_condition_payment,condition_livraison_libelle_langue.ref_condition_livraison,id_a_livre,a_livre.quantite, a_livre.montant",
			   "article,personne,a_livre,condition_payement_libelle_langue,condition_livraison_libelle_langue",
			   "ref_article = id_article AND ref_acheteur = id_personne  AND nom_utilisateur = '$username' and a_livre.ref_statut = '14' AND a_livre.ref_article = id_article AND article.ref_condition_payement = condition_payement_libelle_langue.ref_condition_payment AND  article.ref_condition_livraison  = condition_livraison_libelle_langue.ref_condition_livraison AND article.id_condition_livraison <> 8 LIMIT $index_start, $index_end");	
    

    my $i = 0;
    my $j = 0;
    my $article_payment_mode;
    my $article_livraison_mode;
    
    while( ($ARTICLE{'pochette'}, $ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'ref_vendeur'},$ARTICLE{'payement_mode'},$ARTICLE{'deliver_mode'},$ARTICLE{'id_a_livre'},$ARTICLE{'quantite'},$ARTICLE{'montant'})=$c->fetchrow()) {
	#$string .= " <label>&nbsp;&nbsp;$ARTICLE{'genre'}</label>";
	my ($vendeur_username,$vendeur_name,$vendeur_firstname,$vendeur_adresse,$vendeur_city,$vendeur_npa)= sqlSelect("nom_utilisateur,nom,prenom,adresse,ville,npa", "personne","id_personne = '$ARTICLE{'ref_vendeur'}'");
	if ($ARTICLE{'pochette'} eq '') {
		$ARTICLE{'pochette'} = "../images/no.gif";
	}
        $article_payment_mode = sqlSelect ("libelle.libelle","condition_payement_libelle_langue, libelle, langue","condition_payement_libelle_langue.ref_condition_payment = '$ARTICLE{'payement_mode'}' AND condition_payment_libelle_langue.ref_libelle = libelle.id_libelle AND condition_paymentt_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
        $article_livraison_mode = sqlSelect ("libelle.libelle","condition_livraison_libelle_langue, libelle, langue","condition_livraison_libelle_langue.ref_condition_livraison = '$ARTICLE{'deliver_mode'}' AND condition_livraison_libelle_langue.ref_libelle = libelle.id_libelle AND condition_livraison_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
	$string .= "<tr><td align=\"left\"><img alt=\"\" src=\"$ARTICLE{'pochette'}\" alt=\"\"/></td><td align=\"left\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&amp;action=detailother&amp;article=$ARTICLE{'id_article'}\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'montant'}</td><td align=\"left\">$vendeur_username</td><td align=\"left\">$article_payment_mode</td><td align=\"left\">$article_livraison_mode</td><td align=\"left\"><a href=\"javascript:void(0)\" class=\"menulink\"  onclick=\"window.open('/cgi-bin/recordz.cgi?lang=$lang&amp;page=update_statut_have_receive&amp;session=$session_id&article=$ARTICLE{'id_article'}&id_a_livre=$ARTICLE{'id_a_livre'};','MyWindow','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=no,width=800,height=300,left=20,top=20')\">Update statut</a></td></tr>";
    }
    $string .= "</table>";
    return $string;
        
}

sub loadTableIndexMyBuyBuyWaiting {
    my $article = $query->param("article");
    my $username = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $depot = $query->param("depot");
    $depot =~ s/[^A-Za-z0-9 ]//;
    
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  ($c)= sqlSelectMany("distinct id_article",
			   "article,a_livre,personne",
			   "ref_article = id_article AND ref_acheteur = id_personne  AND nom_utilisateur = '$username' and a_livre.ref_statut = '8'");	
	
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
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&page=myencheredeal&option=mynotdeal;&amp;min_index=$min_index&amp;max_index=$max_index\"  class=\"menulink2\" ><-$j-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }
    if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }        
return $string;    
}

sub loadTableIndexMyBuyToBuyWaiting {
    my $article = $query->param("article");
    my $username = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $depot = $query->param("depot");
    $depot =~ s/[^A-Za-z0-9 ]//;
    
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  ($c)= sqlSelectMany("distinct id_article",
			   "article,a_livre,personne",
			   "ref_article = id_article AND ref_acheteur = id_personne  AND nom_utilisateur = '$username' and a_livre.ref_statut = '14'");	
	
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
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&page=myencheredeal&option=mynotdeal;&amp;min_index=$min_index&amp;max_index=$max_index\"  class=\"menulink2\" ><-$j-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }
        
return $string;    
}


sub loadTableByIndexMyBuyBuyWaiting {

    my $username = shift || '';
    my  $index_start = $query->param ("min_index");
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index");
    $index_end =~ s/[^A-Za-z0-9 ]//;
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

    my  ($c)= sqlSelectMany("DISTINCT id_article,pochette,article.nom,montant,ref_vendeur,condition_payement_libelle_langue.ref_condition_payment, condition_livraison_libelle_langue.ref_condition_livraison, a_paye.quantite",
			   "article,personne,a_paye,condition_payement_libelle_langue,condition_livraison_libelle_langue",
			   "ref_article = id_article AND ref_acheteur = id_personne  AND nom_utilisateur = '$username' and a_paye.ref_statut = '8' AND article.ref_condition_payement = condition_payment_libelle_langue.ref_condition_payement AND  article.ref_condition_livraison  =  condition_livraison_libelle_langue.ref_condition_livraison AND article.id_condition_livraison = 8 LIMIT $index_start, $index_end");	
    

    my $i = 0;
    my $j = 0;
    my $article_mode_payement;
    my $article_mode_livraison;
    $string = "<table style=\"border-width:thin; border-style:dotted; border-top-color:#94CEFA;border-right-color:#94CEFA;border-left-color:#94CEFA; border-bottom-color:#94CEFA\" width=\"555\" border=\"0\"><tr bgcolor=\"#DBE4F8\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"151\">$SERVER{'article_name_label'}</td><td align=\"left\">$SERVER{'article_price_label'}</td><td align=\"left\">Vendeur</td><td align=\"left\">Mode de payement : </td><td align=\"left\"> Livraison : </td><td align=\"left\"></td></tr>";
    while( ($ARTICLE{'id_article'},$ARTICLE{'pochette'}, $ARTICLE{'name'},$ARTICLE{'montant'},$ARTICLE{'ref_vendeur'},$ARTICLE{'payement_mode'},$ARTICLE{'deliver_mode'},$ARTICLE{'id_a_livre'},$ARTICLE{'quantite'})=$c->fetchrow()) {
	#$string .= " <label>&nbsp;&nbsp;$ARTICLE{'genre'}</label>";
	my ($vendeur_username,$vendeur_name,$vendeur_firstname,$vendeur_adresse,$vendeur_city,$vendeur_npa)= sqlSelect("nom_utilisateur,nom,prenom,adresse,ville,npa", "personne","id_personne = '$ARTICLE{'ref_vendeur'}'");
	if ($ARTICLE{'pochette'} eq '') {
		$ARTICLE{'pochette'} = "../images/no.gif";
	}
        $ARTICLE{'payement_mode_name'} = sqlSelect ("libelle.libelle","condition_payement_libelle_langue, libelle, langue","contition_payment_libelle_langue = '$ARTICLE{'payement_mode'}', condition_payement_libelle_langue.ref_libelle = libelle.id_libelle AND condition_payement_libelle_langue.ref_langue AND langue.key = '$lang'");
        $ARTICLE{'deliver_mode_name'} = sqlSelect ("libelle.libelle","condition_livraison_libelle_langue, libelle, langue","condition_livraison_libelle_langue.ref_condition_livraison = '$ARTICLE{'deliver_mode'}' condition_livraison_libelle_langue.ref_condition_livraison.ref_libelle = libelle.id_libelle AND condition_livraison_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' AND condition_livraison_libelle_langue.ref_condition_livraison = ");
	$string .= "<tr><td align=\"left\"><img alt=\"\" src=\"$ARTICLE{'pochette'}\" alt=\"\"/></td><td align=\"left\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&amp;action=detailother&amp;article=$ARTICLE{'id_article'}\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'montant'}</td><td align=\"left\">$vendeur_username</td><td align=\"left\">$article_mode_payement</td><td align=\"left\">$article_mode_livraison</td><td align=\"left\"><a href=\"javascript:void(0)\" class=\"menulink\"  onclick=\"window.open('/cgi-bin/recordz.cgi?lang=$lang&amp;page=update_statut_have_receive&amp;session=$session_id&article=$ARTICLE{'id_article'}&id_a_livre=$ARTICLE{'id_a_livre'};','MyWindow','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=no,width=800,height=300,left=20,top=20')\">Update statut</a></td></tr>";
    }
    $string .= "</table>";
    return $string;
        
}

sub loadTableIndexSoulevement {
    my $param1 = shift || '';
    my $article = $query->param("article");
    my $username = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $depot = $query->param("depot");
    $depot =~ s/[^A-Za-z0-9 ]//;
    
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  ($c)= $db->sqlSelectMany("distinct id_article",
			   "article,met_en_vente,personne,a_livre",
			   "a_livre.ref_article = id_article AND a_livre.ref_vendeur = id_personne  AND nom_utilisateur = '$username' and a_livre.ref_statut = '9' and ref_condition_livraison = 9");	
	
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
	$string .= "<a href=\"/cgi-bin/my_auctions.pl?lang=$lang&amp;session=$session_id&page=myencheredeal&option=mybuysoulevement&amp;min_index=$min_index&amp;max_index=$max_index\"  class=\"menulink2\" ><-$j-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }
    if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }        
return $string;    
	
}

sub loadTableIndexSoulevementAllerChercher {
    my $param1 = shift || '';
    my $article = $query->param("article");
    my $username = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $depot = $query->param("depot");
    $depot =~ s/[^A-Za-z0-9 ]//;
    
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  ($c)= $db->sqlSelectMany("distinct id_article",
			   "article,met_en_vente,personne,a_livre",
			   "a_livre.ref_article = id_article AND a_livre.ref_acheteur = id_personne  AND nom_utilisateur = '$username' and a_livre.ref_statut = '9' and ref_condition_livraison = 9");	
	
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
	$string .= "<a href=\"/cgi-bin/my_auctions.pl?lang=$lang&amp;session=$session_id&page=myencheredeal&option=mybuysoulevement&amp;min_index=$min_index&amp;max_index=$max_index\"  class=\"menulink2\" ><-$j-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }
    if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }        
return $string;    
	
}

sub loadTableByIndexSoulevement {
    loadLanguage();
    my $u = $query->param("u");
    my $param1 = shift || '';
    my $username = shift || '';
    my  $index_start = $query->param ("min_index");
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index");
    $index_end =~ s/[^A-Za-z0-9 ]//;
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

    my  ($c)= $db->sqlSelectMany("pochette,article.nom,id_article,a_livre.ref_acheteur,article.enchere,id_a_livre",
			   "article,personne,a_livre",
			   "a_livre.ref_article = id_article AND a_livre.ref_vendeur = id_personne  AND nom_utilisateur = '$username' and a_livre.ref_statut = '9' AND ref_condition_livraison = 9 LIMIT $index_start, $index_end");	
    
    
    my $i = 0;
    my $j = 0;
	loadLanguage();
    my $string = "<table style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><tr style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"151\">$SERVER{'article_name_label'}</td><td align=\"left\">$SERVER{'fabricant'}</a></td><td align=\"left\">$SERVER{'article_price_label'}</td></tr>";;
    while( ($ARTICLE{'pochette'}, $ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'ref_acheteur'},$ARTICLE{'enchere'},$ARTICLE{'id_a_livre'})=$c->fetchrow()) {
	#$string .= " <label>&nbsp;&nbsp;$ARTICLE{'genre'}</label>";
	my  ($acheteur)= $db->sqlSelect("nom_utilisateur", "personne","id_personne = $ARTICLE{'ref_acheteur'}");	    
	if ($ARTICLE{'enchere'} eq '1') {
		($ARTICLE{'enchere_price'}) =$db->sqlSelect("MAX(prix)", "enchere", "ref_article = '$ARTICLE{'id_article'}'");
	}
	if ($ARTICLE{'pochette'} eq '') {
		$ARTICLE{'pochette'} = "../images/no.gif";
	}
	$ARTICLE{'label'} = substr($ARTICLE{'label'},0, 18);
	$ARTICLE{'label'} .= "...";
	$string .= "<tr><td align=\"left\"><img alt=\"\" src=\"$ARTICLE{'pochette'}\" alt=\"\"/></td><td align=\"left\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&amp;action=detailother&amp;article=$ARTICLE{'id_article'}\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\"><a href=\"javascript:void(0)\" class=\"menulink\"  onclick=\"window.open('/cgi-bin/update_statut_article_soulevement.pl?lang=$lang&amp;page=update_statut_article_waiting_buy&amp;session=$session_id&article=$ARTICLE{'id_article'}&buyer=$acheteur&id_a_livre=$ARTICLE{'id_a_livre'}&u=$u;','MyWindow','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=no,width=800,height=600,left=20,top=20')\">$acheteur</a></td><td align=\"left\">$ARTICLE{'enchere_price'}</td><td align=\"left\"></td></tr>";
	$i += 1;
	$j += 1;

	if ($i eq 1) {		
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
sub loadTableByIndexSoulevementAllerChercher {
    loadLanguage();
    my $u = $query->param("u");
    my $param1 = shift || '';
    my $username = shift || '';
    my  $index_start = $query->param ("min_index");
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index");
    $index_end =~ s/[^A-Za-z0-9 ]//;
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

    my  ($c)= $db->sqlSelectMany("pochette,article.nom,id_article,a_livre.ref_acheteur,article.enchere,id_a_livre",
			   "article,personne,a_livre",
			   "a_livre.ref_article = id_article AND a_livre.ref_acheteur = id_personne  AND nom_utilisateur = '$username' and a_livre.ref_statut = '9' AND ref_condition_livraison = 9 LIMIT $index_start, $index_end");	
    
    
    my $i = 0;
    my $j = 0;
	
    my $string = "<table style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><tr style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"151\">$SERVER{'article_name_label'}</td><td align=\"left\">$SERVER{'fabricant'}</a></td><td align=\"left\">$SERVER{'article_price_label'}</td></tr>";;
    while( ($ARTICLE{'pochette'}, $ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'ref_acheteur'},$ARTICLE{'enchere'},$ARTICLE{'id_a_livre'})=$c->fetchrow()) {
	#$string .= " <label>&nbsp;&nbsp;$ARTICLE{'genre'}</label>";
	my  ($acheteur)= $db->sqlSelect("nom_utilisateur", "personne","id_personne = $ARTICLE{'ref_acheteur'}");	    
	if ($ARTICLE{'enchere'} eq '1') {
		($ARTICLE{'enchere_price'}) =$db->sqlSelect("MAX(prix)", "enchere", "ref_article = '$ARTICLE{'id_article'}'");
	}
	if ($ARTICLE{'pochette'} eq '') {
		$ARTICLE{'pochette'} = "../images/no.gif";
	}
	$ARTICLE{'label'} = substr($ARTICLE{'label'},0, 18);
	$ARTICLE{'label'} .= "...";
	$string .= "<tr><td align=\"left\"><img alt=\"\" src=\"$ARTICLE{'pochette'}\" alt=\"\"/></td><td align=\"left\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&amp;action=detailother&amp;article=$ARTICLE{'id_article'}\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\"><a href=\"javascript:void(0)\" class=\"menulink\"  onclick=\"window.open('/cgi-bin/update_statut_article_soulevement.pl?lang=$lang&amp;page=update_statut_article_waiting_buy&amp;session=$session_id&article=$ARTICLE{'id_article'}&buyer=$acheteur&id_a_livre=$ARTICLE{'id_a_livre'}&u=$u;','MyWindow','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=no,width=800,height=600,left=20,top=20')\">$acheteur</a></td><td align=\"left\">$ARTICLE{'enchere_price'}</td><td align=\"left\"></td></tr>";
	$i += 1;
	$j += 1;

	if ($i eq 1) {		
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

sub loadIndexEffect {
    my $param1 = shift || '';
    my $article = $query->param("article");
    my $username = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $depot = $query->param("depot");
    $depot =~ s/[^A-Za-z0-9 ]//;
    
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  ($c)= $db->sqlSelectMany("distinct id_article",
			   "article,met_en_vente,personne,a_livre",
			   "a_livre.ref_article = id_article AND a_livre.ref_vendeur = id_personne  AND nom_utilisateur = '$username' and a_livre.ref_statut = '16'");	
	
	while( ($ARTICLE{'nom_utilisateur'},$ARTICLE{'question'},$ARTICLE{'texte'},$ARTICLE{'date'})=$c->fetchrow()) {
	    $total +=1;
	}

    my  $nb_page = arrondi ($total / 40, 1);
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
  if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }        
return $string;    
}


sub loadTableByIndexEffect {
    my $param1 = shift || '';
    my $username = shift || '';
    my  $index_start = $query->param ("min_index");
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index");
    $index_end =~ s/[^A-Za-z0-9 ]//;
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

    my  ($c)= $db->sqlSelectMany("pochette,article.nom,id_article,a_livre.ref_vendeur,a_livre.montant,a_livre.quantite",
			   "article,personne,a_livre,met_en_vente",
			   "a_livre.ref_article = id_article AND a_livre.ref_acheteur = id_personne  AND nom_utilisateur = '$username' and a_livre.ref_statut = '16' LIMIT $index_start, $index_end");	
    
    
    my $i = 0;
    my $j = 0;
    loadLanguage();
    $string = "<table style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><tr style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"151\">$SERVER{'article_name_label'}</td><td align=\"left\">$SERVER{'fabricant'}</a></td><td align=\"left\">$SERVER{'article_price_label'}</td></tr>";
    while( ($ARTICLE{'pochette'}, $ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'ref_acheteur'},$ARTICLE{'montant'},$ARTICLE{'quantite'})=$c->fetchrow()) {
	#$string .= " <label>&nbsp;&nbsp;$ARTICLE{'genre'}</label>";
	my  ($acheteur)= $db->sqlSelect("nom_utilisateur", "personne","id_personne = $ARTICLE{'ref_acheteur'}");	    
	if ($ARTICLE{'pochette'} eq '') {
		$ARTICLE{'pochette'} = "../images/no.gif";
	}
	$ARTICLE{'label'} = substr($ARTICLE{'label'},0, 18);
	$ARTICLE{'label'} .= "...";
	$string .= "<tr><td align=\"left\"><img alt=\"\" src=\"$ARTICLE{'pochette'}\" alt=\"\"/></td><td align=\"left\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&amp;action=detailother&amp;article=$ARTICLE{'id_article'}\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$acheteur</td><td align=\"left\">$ARTICLE{'montant'}</td><td align=\"left\">$ARTICLE{'quantite'}</td></tr>";
	$i += 1;
	$j += 1;

	if ($i eq 1) {		
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


sub loadTableIndexMyBuyWaiting {
    my $article = $query->param("article");
    my $call = shift || '';
    my $username = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $depot = $query->param("depot");
    $depot =~ s/[^A-Za-z0-9 ]//;
    
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  ($c)= $db->sqlSelectMany("distinct id_article",
			   "article,met_en_vente,personne,a_paye",
			   "met_en_vente.ref_article = id_article AND met_en_vente.ref_vendeur = id_personne  AND nom_utilisateur = '$username' and a_paye.ref_statut = '8' AND a_paye.ref_vendeur = id_personne AND a_paye.ref_article = id_article");	
	
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
    if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }        
return $string;    
}


sub loadTableByIndexMyBuyWaiting {
    $lang = $query->param("lang");
    my $u = $query->param("u");
    my $call = shift || '';
    my $username = shift || '';
    my  $index_start = $query->param ("min_index");
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index");
    $index_end =~ s/[^A-Za-z0-9 ]//;
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
    my  ($c)= $db->sqlSelectMany("a_paye.ref_acheteur,pochette,article.nom,id_article,id_a_paye,a_paye.quantite,a_paye.montant",
			   "article,personne,a_paye,met_en_vente",
			   "met_en_vente.ref_article = id_article AND met_en_vente.ref_vendeur = id_personne  AND nom_utilisateur = '$username' and (a_paye.ref_statut = '8' or a_paye.ref_statut = '13') AND a_paye.ref_vendeur = id_personne AND a_paye.ref_article = id_article LIMIT $index_start, $index_end");	
    

    my $i = 0;
    my $j = 0;
    
    
    while( ($ARTICLE{'ref_acheteur'},$ARTICLE{'pochette'},$ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'id_a_paye'},$ARTICLE{'quantity'},$ARTICLE{'montant'})=$c->fetchrow()) {
	my  ($achteur)=$db->sqlSelect("nom_utilisateur", "personne", "id_personne = '$ARTICLE{'ref_acheteur'}'");	
	#$string .= " <label>&nbsp;&nbsp;$ARTICLE{'genre'}</label>";
		$string .= "<tr><td align=\"left\"><img alt=\"\" src=\"$ARTICLE{'pochette'}\" alt=\"\"/></td><td align=\"left\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&amp;action=detailother&amp;article=$ARTICLE{'id_article'}\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$achteur</td><td align=\"left\">$ARTICLE{'montant'}</td><td align=\"left\">$ARTICLE{'quantity'}</td><td align=\"left\"><a href=\"javascript:void(0)\" class=\"menulink\"  onclick=\"window.open('/cgi-bin/update_statut_article_buy_waiting.pl?lang=$lang&amp;page=update_statut_article_waiting_buy&amp;session=$session_id&article=$ARTICLE{'id_article'}&buyer=$achteur&id_a_paye=$ARTICLE{'id_a_paye'}&u=$u;','MyWindow','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=no,width=800,height=600,left=20,top=20')\">Update statut</a></td></tr>";
    }
    $string .= "</table>";
    return $string;
        
}

sub loadTableIndexCurrentDeal {
    my $article = $query->param("article");
    my $param1 = shift || '';
    my $username = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $depot = $query->param("depot");
    $depot =~ s/[^A-Za-z0-9 ]//;
    
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  ($c)= $db->sqlSelectMany("distinct id_article",
			   "article,met_en_vente,personne",
			   "ref_article = id_article AND ref_vendeur = id_personne  AND nom_utilisateur = '$username' and article.ref_statut = '3'");	
	
	while( ($ARTICLE{'nom_utilisateur'},$ARTICLE{'question'},$ARTICLE{'texte'},$ARTICLE{'date'})=$c->fetchrow()) {
	    $total +=1;
	}

    my  $nb_page = arrondi ($total / 40, 1);
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
    if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }        
return $string;    
}

sub loadTableAdvertiseIndexCurrentDeal {
    my $article = $query->param("article");
    my $username = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $depot = $query->param("depot");
    
    
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  ($c)= $db->sqlSelectMany("distinct id_article",
			   "article,met_en_vente,personne",
			   "ref_article = id_article AND ref_vendeur = id_personne  AND nom_utilisateur = '$username' and article.ref_statut = '3'");	
	
	while( ($ARTICLE{'nom_utilisateur'},$ARTICLE{'question'},$ARTICLE{'texte'},$ARTICLE{'date'})=$c->fetchrow()) {
	    $total +=1;
	}

    my  $nb_page = arrondi ($total / 40, 1);
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










sub loadCounterMyBuyTable {
    my $call = shift || '';
    my $article = $query->param("article");
    my $username = shift || '';
    my $u = $query->param("u");
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $depot = $query->param("depot");
    $depot =~ s/[^A-Za-z0-9 ]//;
    
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  ($c)= $db->sqlSelectMany("distinct id_article",
			   "article,a_paye,personne",
			   "ref_article = id_article AND ref_acheteur = id_personne  AND nom_utilisateur = '$username' and a_paye.ref_statut = '8'");	
	
	while( ($ARTICLE{'nom_utilisateur'},$ARTICLE{'question'},$ARTICLE{'texte'},$ARTICLE{'date'})=$c->fetchrow()) {
	    $total +=1;
	}

    my  $nb_page = arrondi ($total / 40, 1);
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
    if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }        
return $string;    
}


sub loadMyBuyToBuyTable {
    $lang = $query->param("lang");
    loadLanguage();
    my $call = shift || '';	
    my $username = shift || '';
    my $u = $query->param("u");
    my  $index_start = $query->param ("min_index");
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index");
    $index_end =~ s/[^A-Za-z0-9 ]//;
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

    my  ($c)= $db->sqlSelectMany("pochette,article.nom,id_article,marque,a_paye.montant,a_paye.quantite,a_paye.id_a_paye",
			   "article,personne, a_paye",
			   "a_paye.ref_article = id_article AND a_paye.ref_acheteur = id_personne AND nom_utilisateur = '$username' and a_paye.ref_statut = '8' and a_paye.ref_acheteur = id_personne LIMIT $index_start, $index_end");	
    

    my $i = 0;
    my $j = 0;
    my $encrypt =  &string2hex(&RC4($username,$the_key));
    my$string = "<table style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><tr style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"151\">$SERVER{'article_name_label'}</td><td align=\"left\">$SERVER{'fabricant'}</a></td><td align=\"left\">$SERVER{'article_price_label'}</td></tr>";;
    #$string = "<table style=\"border-width:thin; border-style:dotted; border-top-color:#94CEFA;border-right-color:#94CEFA;border-left-color:#94CEFA; border-bottom-color:#94CEFA\" width=\"555\" border=\"0\"><tr bgcolor=\"#DBE4F8\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"151\">$SERVER{'article_name_label'}</td><td align=\"left\">$SERVER{'article_price_label'}</td><td>$SERVER{'article_quantity_wanted'}</td></tr>";
    while( ($ARTICLE{'pochette'}, $ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'marque'},$ARTICLE{'price'},$ARTICLE{'quantity'},$ARTICLE{'id_a_paye'})=$c->fetchrow()) {
	#$string .= " <label>&nbsp;&nbsp;$ARTICLE{'genre'}</label>";
	if ($ARTICLE{'pochette'} eq '') {
		$ARTICLE{'pochette'} = "../images/no.gif";
	}
	$ARTICLE{'label'} = substr($ARTICLE{'label'},0, 18);
	$ARTICLE{'label'} .= "...";
	$string .= "<tr><td align=\"left\"><img alt=\"\" src=\"$ARTICLE{'pochette'}\" alt=\"\"/></td><td align=\"left\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&amp;action=detailother&amp;article=$ARTICLE{'id_article'}\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'price'}</td><td>$ARTICLE{'quantity'}</td></td><td align=\"left\">$ARTICLE{'payement_mode'}</td><td align=\"left\">$ARTICLE{'deliver_mode'}</td><td align=\"left\"><a href=\"javascript:void(0)\" class=\"menulink\"  onclick=\"window.open('/cgi-bin/update_statut_article_payed.pl?lang=$lang&amp;page=update_statut_article_payed&amp;session=$session_id&article=$ARTICLE{'id_article'}&user=$encrypt&id_paye=$ARTICLE{'id_a_paye'};','MyWindow','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=no,width=800,height=300,left=20,top=20')\">Update statut</a></td></tr>";
    }
    $string .= "</table>";
    return $string;
    
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

sub loadTableByIndexCurrentDeal {
	my  $lang = $query->param ("lang");
    my $param1 = shift || '';
    my $decrypted = shift || '';
    my $u = $query->param("u");
    #my $decrypted =  &RC4(&hex2string($u),$the_key);
    my  $index_start = $query->param ("min_index");
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index");
    $index_end =~ s/[^A-Za-z0-9 ]//;
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

    my  ($c)= $db->sqlSelectMany("pochette,article.nom,id_article,marque,prix,quantite,date_stock",
			   "article,personne,met_en_vente",
			   "ref_article = id_article AND ref_vendeur = id_personne  AND nom_utilisateur = '$decrypted' and article.ref_statut = '3' LIMIT $index_start, $index_end");	
    

    my $i = 0;
    my $j = 0;
    loadLanguage();
    my $string = "<table style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><tr style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"151\">$SERVER{'article_name_label'}</td><td align=\"left\">$SERVER{'fabricant'}</a></td><td align=\"left\">$SERVER{'article_price_label'}</td><td align=\"left\">$SERVER{'quantity'}</td></tr>";;
    while( ($ARTICLE{'pochette'}, $ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'marque'},$ARTICLE{'price'},$ARTICLE{'quantity'},$ARTICLE{'date_stock'})=$c->fetchrow()) {
	#$string .= " <label>&nbsp;&nbsp;$ARTICLE{'genre'}</label>";
	if ($ARTICLE{'pochette'} eq '') {
		$ARTICLE{'pochette'} = "../images/no.gif";
	}
	$ARTICLE{'label'} = substr($ARTICLE{'label'},0, 18);
	$ARTICLE{'label'} .= "...";
	$string .= "<tr><td align=\"left\"><img alt=\"\" src=\"$ARTICLE{'pochette'}\" alt=\"\"/></td><td align=\"left\"><a href=\"/cgi-bin/detail.pl?lang=$lang&amp;session=$session_id&amp;action=detailother&amp;article=$ARTICLE{'id_article'}\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'marque'}</td><td align=\"left\">$ARTICLE{'price'}</td><td align=\"left\">$ARTICLE{'quantity'}</td></tr>";
    }
    $string .= "</table>";
    return $string;
        
}

sub loadTableAdvertiseByIndexCurrentDeal {
    $lang = $query->param("lang");	
    loadLanguage();
    my $u = $query->param("u");
    my $x  = shift || '';
    my $xy  = shift || '';
    my $decrypted =  &RC4(&hex2string($u),$the_key);
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

    my  ($c)= $db->sqlSelectMany("pochette,article.nom,id_article,marque,prix,quantite,date_stock",
			   "article,personne,met_en_vente",
			   "ref_article = id_article AND ref_vendeur = id_personne  AND nom_utilisateur = '$xy' and article.ref_statut = '3' LIMIT $index_start, $index_end");	
    

    my $i = 0;
    my $j = 0;
    my  $string = "<table style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><tr<td align=\"left\" width=\"51\"></td><td align=\"left\" width=\"151\"></td><td align=\"left\"></a></td><td align=\"left\"></td></tr>";
    while( ($ARTICLE{'pochette'}, $ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'marque'},$ARTICLE{'price'},$ARTICLE{'quantity'},$ARTICLE{'date_stock'})=$c->fetchrow()) {
	#$string .= " <label>&nbsp;&nbsp;$ARTICLE{'genre'}</label>";
	if ($ARTICLE{'pochette'} eq '') {
		$ARTICLE{'pochette'} = "../images/no.gif";
	}
	$ARTICLE{'label'} = substr($ARTICLE{'label'},0, 18);
	$ARTICLE{'label'} .= "...";
	$string .= "<tr><td align=\"left\"><img alt=\"\" src=\"$ARTICLE{'pochette'}\" alt=\"\"/></td><td align=\"left\"><a href=\"/cgi-bin/detail.pl?lang=$lang&amp;session=$session_id&amp;action=detailother&amp;article=$ARTICLE{'id_article'}\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'marque'}</td><td align=\"left\">$ARTICLE{'price'}</td><td align=\"left\">$ARTICLE{'date_stock'}</td><td align=\"left\">$ARTICLE{'quantity'}</td><td><a class=\"menulink\" href=\"#\" onclick=\"window.open('/cgi-bin/promote.pl?lang=$lang&page=promote&article=$ARTICLE{'id_article'}&u=$u&name=$ARTICLE{'name'};','MySearchWindow','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes,width=1024,height=200,left=0,top=0')\">Promouvoir</a></td></tr>";
    }
    $string .= "</table>";
    return $string;
        
}

sub loadTableIndexInvendu {
    my $param1 = shift || '';
    my $article = $query->param("article");
    my $username = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $depot = $query->param("depot");
    $depot =~ s/[^A-Za-z0-9 ]//;
    
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  ($c)= $db->sqlSelectMany("id_article",
			   "article,met_en_vente,personne",
			   "ref_article = id_article AND ref_vendeur = id_personne AND nom_utilisateur = '$username' and article.ref_statut = '11'");	
	
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
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&page=myencheredeal&option=mynotdeal;&amp;min_index=$min_index&amp;max_index=$max_index\"  class=\"menulink2\" ><-$j-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }
    if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }        
return $string;    
}

sub loadTableIndexToDeliver {
	my $lang = $query->param("lang");
    my $article = $query->param("article");
    my $param1 = shift || '';
    my $username = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $depot = $query->param("depot");
    $depot =~ s/[^A-Za-z0-9 ]//;
    
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  ($c)= $db->sqlSelectMany("distinct id_article",
			   "article,a_livre,personne",
			   "ref_article = id_article AND ref_vendeur = id_personne  AND nom_utilisateur = '$username' and a_livre.ref_statut = '14' AND article.ref_condition_livraison <> 8");	
	
	while( ($ARTICLE{'nom_utilisateur'},$ARTICLE{'question'},$ARTICLE{'texte'},$ARTICLE{'date'})=$c->fetchrow()) {
	    $total +=1;
	}

    my  $nb_page = arrondi ($total / 40, 1);
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
	$string .= "<a href=\"/cgi-bin/my_auctions.pl?lang=$lang&amp;session=$session_id&page=myencheredeal&option=mybuytodeliver;&amp;min_index=$min_index&amp;max_index=$max_index\"  class=\"menulink2\" ><-$j-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }
    if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }        
return $string;    
}

sub loadIndexWaitDeliver {
    my $article = $query->param("article");
    my $param1 = shift || '';
    my $username = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $depot = $query->param("depot");
    $depot =~ s/[^A-Za-z0-9 ]//;
    
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  ($c)= $db->sqlSelectMany("distinct id_article",
			   "article,a_livre,personne",
			   "ref_article = id_article AND ref_acheteur = id_personne  AND nom_utilisateur = '$username' and (a_livre.ref_statut = '14' or a_livre.ref_statut = '9') AND article.ref_condition_livraison <> 8 AND article.ref_condition_livraison <> 9");	
	
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
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&page=myencheredeal&option=mynotdeal;&amp;min_index=$min_index&amp;max_index=$max_index\"  class=\"menulink2\" ><-$j-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }
    if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }        
return $string;    
}

sub loadTableByIndexToDeliver {
    my $u = $query->param("u");
    $lang = $query->param("lang");
    loadLanguage();
    my $call = shift || '';
    my $username = shift || '';
    my  $index_start = $query->param ("min_index");
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index");
    $index_end =~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);

    my  $add;
    my  $add2;
    my  $dep;
    
    if (!$index_start ) {
	$index_start = 0;
    }
    if (!$index_end ) {
	$index_end = 40;
    }
    
    my ($c)= $db->sqlSelectMany("DISTINCT pochette,article.nom,ref_acheteur,a_livre.id_a_livre,condition_livraison_libelle_langue.ref_condition_livraison, a_livre.quantite,id_article",
			   "article,a_livre,personne,condition_livraison_libelle_langue",
			   "ref_article = id_article AND ref_vendeur = id_personne  AND nom_utilisateur = '$username' and a_livre.ref_statut = '9' AND article.ref_condition_livraison <> 8 and article.ref_condition_livraison = condition_livraison_libelle_langue.ref_condition_livraison LIMIT $index_start, $index_end");	
    
    
    my $i = 0;
    my $j = 0;
   my  $string = "<table style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><tr style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"151\">$SERVER{'article_name_label'}</td><td align=\"left\">$SERVER{'fabricant'}</a></td><td align=\"left\">$SERVER{'article_price_label'}</td></tr>";
    while( ($ARTICLE{'pochette'}, $ARTICLE{'name'},$ARTICLE{'ref_acheteur'},$ARTICLE{'id_a_livre'},$ARTICLE{'condition_livraison'},$ARTICLE{'quantity'},$ARTICLE{'id_article'})=$c->fetchrow()) {
	#$string .= " <label>&nbsp;&nbsp;$ARTICLE{'genre'}</label>";
	my ($buyer) = $db->sqlSelect("nom_utilisateur", "personne", "id_personne = '$ARTICLE{'ref_acheteur'}'");	
	if ($ARTICLE{'pochette'} eq '') {
		$ARTICLE{'pochette'} = "../images/no.gif";
	}
        my ($article_mode_livraison) = $db->sqlSelect("libelle.libelle","condition_livraison_libelle_langue,libelle, langue","condition_livraison_libelle_langue.ref_condition_livraison = '$ARTICLE{'condition_livraison'}' AND condition_livraison_libelle_langue.ref_libelle = libelle.id_libelle AND condition_livraison_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
	$ARTICLE{'label'} = substr($ARTICLE{'label'},0, 18);
	$ARTICLE{'label'} .= "...";
	$string .= "<tr><td align=\"left\"><img alt=\"\" src=\"$ARTICLE{'pochette'}\" alt=\"\"/></td><td align=\"left\">$ARTICLE{'name'}</a></td><td><a href=\"javascript:void(0)\" class=\"menulink\"  onclick=\"window.open('/cgi-bin/detail_user.pl?lang=$lang&amp;page=detail_buyer&buyer=$buyer&amp;session=$session_id&id_a_livre=$ARTICLE{'id_a_livre'}&article=$ARTICLE{'id_article'}&u=$u','MyWindow','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=no,width=700,height=460,left=20,top=20')\">$buyer</a></td><td>$ARTICLE{'quantity'}</TD><td>$article_mode_livraison</td><td> <a href=\"javascript:void(0)\" class=\"menulink\"  onclick=\"window.open('/cgi-bin/load_page_update_statut_delivered.pl?lang=$lang&amp;page=update_statut_send_article&buyer=$buyer&amp;session=$session_id&id_a_livre=$ARTICLE{'id_a_livre'}&article=$ARTICLE{'id_article'}&u=$username','MyWindow','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=no,width=680,height=420,left=20,top=20')\">$SERVER{'update_statut'}</a></td></tr>";
	$i += 1;
	$j += 1;

	if ($i eq 1) {		
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


sub loadTableWaitDeliver {
    $lang =$query->param("lang");
    loadLanguage();
    my $u = $query->param("u");
    my $call = shift || '';
    my $username = shift || '';
    my  $index_start = $query->param ("min_index");
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index");
    $index_end =~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);

    my  $add;
    my  $add2;
    my  $dep;
    
    if (!$index_start ) {
	$index_start = 0;
    }
    if (!$index_end ) {
	$index_end = 40;
    }
    
    my ($c)= $db->sqlSelectMany("DISTINCT id_article, pochette,article.nom,ref_vendeur,a_livre.id_a_livre,condition_livraison_libelle_langue.ref_condition_livraison, a_livre.quantite,id_article",
			   "article,a_livre,personne,condition_livraison_libelle_langue",
			   "ref_article = id_article AND ref_acheteur = id_personne  AND nom_utilisateur = '$username' and (a_livre.ref_statut = 9 or a_livre.ref_statut = 14)  AND article.ref_condition_livraison <> 8 and article.ref_condition_livraison <> 9 and article.ref_condition_livraison = condition_livraison_libelle_langue.ref_condition_livraison LIMIT $index_start, $index_end");	
    
    
    my $i = 0;
    my $j = 0;
    my $string = "<table style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><tr style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"151\">$SERVER{'article_name_label'}</td><td align=\"left\">$SERVER{'fabricant'}</a></td><td align=\"left\">$SERVER{'article_price_label'}</td></tr>";;
    while( ($ARTICLE{'id_article'},$ARTICLE{'pochette'}, $ARTICLE{'name'},$ARTICLE{'ref_vendeur'},$ARTICLE{'id_a_livre'},$ARTICLE{'condition_livraison'},$ARTICLE{'quantity'},$ARTICLE{'id_article'})=$c->fetchrow()) {
	#$string .= " <label>&nbsp;&nbsp;$ARTICLE{'genre'}</label>";
	my ($seller) = $db->sqlSelect("nom_utilisateur", "personne", "id_personne = '$ARTICLE{'ref_vendeur'}'");	
	if ($ARTICLE{'pochette'} eq '') {
		$ARTICLE{'pochette'} = "../images/no.gif";
	}
        my ($article_mode_livraison) = $db->sqlSelect("libelle.libelle","condition_livraison_libelle_langue,libelle, langue","condition_livraison_libelle_langue.ref_condition_livraison = '$ARTICLE{'condition_livraison'}' AND condition_livraison_libelle_langue.ref_libelle = libelle.id_libelle AND condition_livraison_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
	
	$ARTICLE{'label'} = substr($ARTICLE{'label'},0, 18);
	$ARTICLE{'label'} .= "...";
	$string .= "<tr><td align=\"left\"><img alt=\"\" src=\"$ARTICLE{'pochette'}\" alt=\"\"/></td><td align=\"left\">$ARTICLE{'name'}</a></td><td>$seller</td><td>$article_mode_livraison</td><td> <a href=\"javascript:void(0)\" class=\"menulink\"  onclick=\"window.open('/cgi-bin/update_article_recieved.pl?lang=$lang&amp;page=update_article_received&seller=$seller&amp;session=$session_id&id_a_livre=$ARTICLE{'id_a_livre'}&article=$ARTICLE{'id_article'}&u=$u','MyWindow','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=no,width=430,height=150,left=20,top=20')\">$SERVER{'update_statut'}</a></td></tr>";
	$i += 1;
	$j += 1;

	if ($i eq 1) {		
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

sub loadTableByIndexInvendu {
    loadLanguage();
    my $lang = $query->param("lang");
    my $param1 = shift || '';
    my $username = shift || '';
    my  $index_start = $query->param ("min_index");
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index");
    $index_end =~ s/[^A-Za-z0-9 ]//;
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

    my  ($c)= $db->sqlSelectMany("article.pochette,article.nom,id_article,article.prix",
			   "article,met_en_vente,personne",
			   "ref_article = id_article AND ref_vendeur = id_personne AND nom_utilisateur = '$username' and article.ref_statut = '11' LIMIT $index_start, $index_end");	
    

    my $i = 0;
    my $j = 0;
    my $string = "<table style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><tr style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"151\">$SERVER{'article_name_label'}</td><td align=\"left\">$SERVER{'fabricant'}</a></td><td align=\"left\">$SERVER{'article_price_label'}</td></tr>";;
    while( ($ARTICLE{'pochette'}, $ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'price'})=$c->fetchrow()) {
	#$string .= " <label>&nbsp;&nbsp;$ARTICLE{'genre'}</label>";
	if ($ARTICLE{'pochette'} eq '') {
		$ARTICLE{'pochette'} = "../images/no.gif";
	}
	$ARTICLE{'label'} = substr($ARTICLE{'label'},0, 18);
	$ARTICLE{'label'} .= "...";
	$string .= "<tr><td align=\"left\"><img alt=\"\" src=\"$ARTICLE{'pochette'}\" alt=\"\"/></td><td align=\"left\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&amp;action=detailother&amp;article=$ARTICLE{'id_article'}\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'price'}</td><td align=\"left\">$ARTICLE{'date_stock'}</td><td align=\"left\"><a href=\"javascript:void(0)\" class=\"menulink\"  onclick=\"window.open('/cgi-bin/deal_again.pl?lang=$lang&amp;page=deal_again&amp;session=$session_id&article=$ARTICLE{'id_article'}&name=$ARTICLE{'name'}','MyWindow','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=no,width=800,height=300,left=20,top=20')\">Remettre en vente</a></td></tr>";
	
    }
    $string .= "</table>";
    return $string;
        
}

sub doBestOfferIndex {
    my $option = $query->param("enchere");
    my $dealer = $query->param("username");
    my $vendu = $query->param("vendu");
    my  $from = "article";
    my  $where;
    my $string;
    
    my  $total = '0';
    
    my  ($c)= sqlSelectMany("DISTINCT article.nom,id_article,pochette","personne,met_en_vente, article","met_en_vente.ref_vendeur = id_personne AND met_en_vente.ref_article = article.id_article");
    while( ($ARTICLE{'name'})=$c->fetchrow()) {
	    $total +=1;
	}
    my  $nb_page = arrondi ($total / 10, 1);
    my  $min_index = '0';
    my  $max_index = '40';

    for (my  $i = '0'; $i < $nb_page;$i++) {
	my $n2 = $i %= 10;
	if ($n2 ne '0') {
		#$string .= "<br />";
	}
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&page=profil_vendeur&username=$dealer&enchere=$option&min_index=$min_index&max_index=$max_index\"  class=\"menulink2\" ><-$i-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }
    if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }    
    return $string;
}

sub doBestOfferIndexed {
    my $option = $query->param("enchere");
    my $dealer = $query->param("username");
    my $vendu = $query->param("vendu");
    my  $index_start = $query->param ("min_index") ;
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index") ;
    $index_end=~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d",$year+1900,$mon+1,$mday;
    
    if (!$index_start ) {
	$index_start = 0;
    }
    if (!$index_end ) {
	$index_end = 40;
    }
   my	$string .= "<table width=\"500\" border=\"0\"><tr bgcolor=\"#DBE4F8\"><td align=\"left\">$SERVER{'image'}</td><td align=\"left\" >$SERVER{'article_name_label'}</td></tr>";
    

   my  ($c)= sqlSelectMany("DISTINCT article.nom,id_article,pochette","personne,met_en_vente, article","met_en_vente.ref_vendeur = id_personne AND met_en_vente.ref_article = article.id_article LIMIT $index_start, $index_end");

	 while( ($ARTICLE{'nom'},$ARTICLE{'id_article'},$ARTICLE{'pochette'})=$c->fetchrow()) {
		$string .= "<tr><td align=\"left\"><img alt=\"\" src=\"$ARTICLE{'pochette'}\"></td><td align=\"left\">$ARTICLE{'nom'}</td></tr>";
	}
    $string .="</table>";    
    return $string;
}


sub evalArticleIndex {
    my $username = $query->param("username");
    my  ($c)= sqlSelect("count(id_evaluation_article)", "personne,evaluation_article","nom_utilisateur = '$username' AND evaluation_article.ref_vendeur = id_personne");	
    my  $nb_page = arrondi ($c / 40, 1);
    my  $min_index = '0';
    my  $max_index = '40';
    my $string;
    for (my  $i = '0'; $i < $nb_page;$i++) {
	my $n2 = $i %= 4;
	if ($n2 ne '0') {
	}
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&page=profil_vendeur&username=$username&option=evalarticle&min_index=$min_index&max_index=$max_index\"  class=\"menulink2\" ><-$i-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }
    if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }    
    return $string;
}
sub evalArticleTable {
    my $content;
    my $username = $query->param("username");
    my  $index_start = $query->param ("min_index") ;
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index") ;
    $index_end=~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d",$year+1900,$mon+1,$mday;
    if (!$index_start ) {$index_start = 0;}
    if (!$index_end ) {$index_end = 40;}
    my	$string .= "<table width=\"500\" border=\"0\"><tr bgcolor=\"#DBE4F8\"><td>$SERVER{'image'}</td><td width=\"200px\">$SERVER{'name'}</td><td align=\"left\">$SERVER{'buyer'}</td><td>$SERVER{'note'}</td><td width=\"300px\"></td></tr>";
    my  ($c)= sqlSelectMany("ref_acheteur,note,date,ref_article", "personne,evaluation_article","nom_utilisateur = '$username' AND evaluation_article.ref_vendeur = id_personne  LIMIT $index_start, $index_end ");	
	 while( ($ARTICLE{'ref_acheteur'},$ARTICLE{'note'},$ARTICLE{'date'},$ARTICLE{'ref_article'})=$c->fetchrow()) {
		($ARTICLE{'acheteur'})= sqlSelect("nom_utilisateur", "personne","id_personne = $ARTICLE{'ref_acheteur'}");
		my $img_star = "";
		for (my $k = 0; $k < $ARTICLE{'note'}; $k++) {$img_star .= "<img src=\"../images/short_star2.gif\">&nbsp;";}
		($ARTICLE{'nom'},$ARTICLE{'pochette'})= sqlSelect("article.nom,pochette", "article","id_article = $ARTICLE{'ref_article'}");						      
		$string .= "<tr><td><img src=\"../images/$ARTICLE{'pochette'}\"></td><td><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&page=profil_vendeur&username=$ARTICLE{'acheteur'}&amp;option=evaldeal\" class=\"menulink\" >$ARTICLE{'nom'}</a></td><td align=\"left\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&page=profil_vendeur&username=$ARTICLE{'acheteur'}&amp;option=evaldeal\" class=\"menulink\" >$ARTICLE{'acheteur'}</a></td><td>$ARTICLE{'note'}</td><td>$img_star</td></tr>";
	}
    $string .="</table>";    
    return $string;

}


sub loadEvalDealNegativIndex {
    my $username = $query->param("username");
    my  ($c)= sqlSelect("ref_acheteur,commentaire,note,date", "personne,evaluation_vente","nom_utilisateur = '$username' AND evaluation_vente.ref_vendeur = id_personne  AND note BETWEEN 0 AND 4");	   
    my  $nb_page = arrondi ($c / 40, 1);
    my  $min_index = '0';
    my  $max_index = '40';
    my $string;
    for (my  $i = '0'; $i < $nb_page;$i++) {
	my $n2 = $i %= 4;
	if ($n2 ne '0') {#$string .= "<br />";}
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&page=profil_vendeur&username=$username&option=evaldeal&min_index=$min_index&max_index=$max_index\"  class=\"menulink2\" ><-$i-></a>&#160;&nbsp;";		
	$min_index += 40;	
}
}
   if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }
   return $string;
}
sub loadEvalDealNegativTable {
    my $content;
    my $username = $query->param("username");
    my  $index_start = $query->param ("min_index") ;
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index") ;
    $index_end=~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d",$year+1900,$mon+1,$mday;
    if (!$index_start ) {$index_start = 0;}
    if (!$index_end ) {$index_end = 40;}
    my	$string .= "<table width=\"500\" border=\"0\"><tr bgcolor=\"#DBE4F8\"><td align=\"left\">$SERVER{'buyer'}</td><td align=\"left\" >$SERVER{'commentaire'}</td><td>$SERVER{'note'}</td></tr>";
    my  ($c)= sqlSelectMany("ref_acheteur,commentaire,note,date", "personne,evaluation_vente","nom_utilisateur = '$username' AND evaluation_vente.ref_vendeur = id_personne  AND note BETWEEN 0 AND 4 LIMIT $index_start, $index_end ");	
	 while( ($ARTICLE{'ref_acheteur'},$ARTICLE{'commentaire'},$ARTICLE{'note'},$ARTICLE{'date'})=$c->fetchrow()) {
		($ARTICLE{'acheteur'})= sqlSelect("nom_utilisateur", "personne","id_personne = $ARTICLE{'ref_acheteur'}");
		$string .= "<tr><td align=\"left\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&page=profil_vendeur&username=$ARTICLE{'acheteur'}&amp;option=evaldeal\" class=\"menulink\" >$ARTICLE{'acheteur'}</a></td><td>$ARTICLE{'commentaire'}</td><td>$ARTICLE{'note'}</td></tr>";
	}
    $string .="</table>";    
    return $string;

}



sub loadInformatiqueIndex {
    my  $cat = shift || '';
    my  $type = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $depot = $query->param("depot");
    my  $subcat = $query->param("subcat");
    $depot =~ s/[^A-Za-z0-9 ]//;
    
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  $add;
    my  $add2;
    my  $dep;

    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");

    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my $from;
    if ($subcat) {
	$add = "AND article.ref_subcategorie = subcategorie_libelle_langue.ref_subcategorie AND subcategorie_libelle_langue.ref_subcategorie = (SELECT subcategorie_libelle_langue.ref_subcategorie FROM subcategorie_libelle_langue FROM subcategorie_libelle_langue, libelle, langue WHERE libelle.libelle = '$subcat' AND subcategorie_libelle_langue.ref_libelle = libelle.libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	$from .= ", subcategorie_$lang";
    } else {
	$add = "";
    }
    if ($type) {
	#$add2 = "AND id_categorie = '$type'";
    } else {
	$add2 = "";		
    }
    if ($depot) {
	$dep = "AND ref_depot = (SELECT id_depot FROM depot WHERE ville = '$depot')";
    }

    my  ($c)= sqlSelect("count(id_article)",
			   "article,met_en_vente,categorie_libelle_langue $from",
			   "ref_article = id_article and article.ref_categorie = id_categorie and id_article = id_article AND article.ref_statut = '3'  AND article.ref_categorie = '10' AND enchere_date_fin > '$date $time ' $add $add2 $dep");	
	
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
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&amp;min_index=$min_index&amp;max_index=$max_index&page=informatique&country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=with_lang_french&with_lang_italian=$with_lang_italian&amp;with_lang_german=with_lang_german&with_lang_english=$with_lang_english\"  class=\"menulink2\" ><-$j-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }
    if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }        
return $string;    
}


sub viewAutoNewsByIndex {
    my  $cat = shift || '';
    my  $type = $query->param("type")  || '';
    my  $depot = $query->param("depot") ;
    my  $subcat = $query->param("subcat");
    $depot=~ s/[^A-Za-z0-9 ]//;
    my  $index_start = $query->param ("min_index");
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index");
    $index_end =~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();

    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $string = "";
    my  $add;
    my  $add2;
    my  $dep;
    
    if (!$index_start ) {$index_start = 0;}
    if (!$index_end ) {$index_end = 40;}
    my $from;
    if ($subcat) {$add = "article.ref_subcategorie = subcategorie_libelle_langue.ref_subcategorie AND subcategorie_libelle_langue.ref_subcategorie = (SELECT subcategorie_libelle_langue.ref_subcategorie FROM subcategorie_libelle_langue, libelle, langue WHERE libelle.libelle = '$subcat' AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
                  $from .= ",subcategorie_libelle_langue";}
    my $add3;
    $add3 = getAdd();
    my  ($c)= sqlSelectMany("DISTINCT article.nom,marque,prix, pochette,id_article,date_stock,article.ref_categorie,article.lieu",
		       "article,met_en_vente $from",
		       "ref_article = id_article  AND met_en_vente.page_categorie  = 'on' AND ref_statut = '3'  AND article.ref_categorie= '8' AND  enchere_date_fin > "." '$date%'  $add $add3 ORDER BY  date_stock DESC LIMIT $index_start, $index_end");	
    my $i = 0;my $j = 0;
    $string .= "<table style=\"border-top-width:medium;border-top-color:#94CEFA\"><tr>";
    
    while( ($ARTICLE{'name'},$ARTICLE{'author'},$ARTICLE{'price'},$ARTICLE{'pochette'},$ARTICLE{'id_article'},$ARTICLE{'date'},$ARTICLE{'ref_categorie'},$ARTICLE{'article_lieu'})=$c->fetchrow()) {
	if ($ARTICLE{'pochette'} eq '') {$ARTICLE{'pochette'} = "../images/no.gif";}	
	if ($ARTICLE{'ref_categorie'} eq '11') {$add3 = $ARTICLE{'article_lieu'};}
	my $img;
	if ($ARTICLE{'date'} eq $date) {$img = "../images/new_article.gif"
	}else {}
	$string .= "<td align=\"left\" width=\"253px\" height=\"100px\" style=\"background-image:url(../images/table_article_decoration.jpg);background-position:right bottom;background-repeat: no-repeat;\">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&amp;action=detailother&amp;article=$ARTICLE{'id_article'}\" class=\"menulink3\" >$ARTICLE{'name'} $add3</a><br/>&nbsp;&nbsp;&nbsp;&nbsp;<img alt=\"\" src=\"$ARTICLE{'pochette'}\" /> <img alt=\"\" src=\"$img\" /><br/>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$ARTICLE{'price'}<br/><br/></td>";
	$i += 1;$j += 1;
	if ($i eq 1) {$string .= "<td align=\"left\" width=\"10px\"></td>";$i = 0;}	
	if ($j eq 2) {$string .= "</tr><tr></tr><tr></tr><tr>";$j = 0;}
    }    
    $string .= "</table>";
    return $string;
}


sub loadArticleFromShopByIndex {
    my  $cat = shift || '';
    my  $type = shift  || '';
    my  $depot = $query->param("depot") ;
    $depot=~ s/[^A-Za-z0-9 ]//;
    my  $index_start = $query->param ("min_index");
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index");
    $index_end =~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    $date = trimwhitespace($date);
    my  $string = "";
    my  $add;
    my  $add2;
    my  $dep;
    
    if (!$index_start ) {$index_start = 0; }
    if (!$index_end ) {$index_end = 40;}

    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");

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
     $add .= getAdd();

    my  ($c)= sqlSelectMany("DISTINCT article.nom,marque,prix, pochette,id_article,date_stock,ref_categorie,article.lieu,quantite",
		       "article,met_en_vente",
		       "ref_article = id_article  AND ref_statut = '3' and quantite > 0 AND  enchere_date_fin > "." '$date%' and enchere <> 1 $add ORDER BY  date_stock DESC LIMIT $index_start, $index_end  ");	    
    my $i = 0; my $j = 0;
    $string .= "<table style=\"border-top-width:medium;border-top-color:#94CEFA\"><tr>";   
    while( ($ARTICLE{'name'},$ARTICLE{'author'},$ARTICLE{'price'},$ARTICLE{'pochette'},$ARTICLE{'id_article'},$ARTICLE{'date'},$ARTICLE{'ref_categorie'},$ARTICLE{'article_lieu'},$ARTICLE{'quantity'})=$c->fetchrow()) {
	#$string .= " <label>&nbsp;&nbsp;$ARTICLE{'genre'}</label>";
	my $img;
	if ($ARTICLE{'pochette'} eq '') {$ARTICLE{'pochette'} = "../images/blank.gif";}	
	if ($ARTICLE{'date'} eq $date) {$img = "../images/new_article.gif"}else {}
	my $add3;
	if ($ARTICLE{'ref_categorie'} eq '11') {$add3 = $ARTICLE{'article_lieu'};}
	$string .= "<td align=\"left\" width=\"253px\" height=\"100px\" style=\"background-image:url(../images/table_article_decoration.jpg);background-position:right bottom;background-repeat: no-repeat;\">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href=\"/cgi-bin/detail.pl?lang=$lang&amp;session=$session_id&amp;action=detailother&amp;article=$ARTICLE{'id_article'}\" class=\"menulink3\" >$ARTICLE{'name'} $add3</a><br/>&nbsp;&nbsp;&nbsp;&nbsp;<img alt=\"\" src=\"$ARTICLE{'pochette'}\" /> <img alt=\"\" src=\"$img\" /><br/>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$ARTICLE{'price'}<br/><br/></td>";
	$i += 1;$j += 1;
	if ($i eq 1) {$string .= "<td align=\"left\" width=\"10px\"></td>";$i = 0;}	
	if ($j eq 2) {$string .= "</tr><tr>";$j = 0;}
    }    
    $string .= "</tr></table>";
    return $string;
    
}




sub viewArticleSelectionByIndex {
    my  $cat = shift || '';
    my  $type = shift  || '';
    my  $depot = $query->param("depot") ;
    $depot=~ s/[^A-Za-z0-9 ]//;
    my  $index_start = $query->param ("min_index_our_selection");
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index_our_selection");
    $index_end =~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $string = "";
    my  $add;
    my  $add2;
    my  $dep;

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

    $add .= getAdd();
    my  ($c)= sqlSelectMany("DISTINCT article.nom,marque,prix, pochette,id_article,ref_categorie,article.lieu",
		       "article,met_en_vente",
		       "ref_article = id_article  AND met_en_vente.notre_selection = '1' AND ref_statut = '3' $add LIMIT $index_start, $index_end");	
    
    my $i = 0;
    my $j = 0;
    $string .= "<table><tr>";
    while( ($ARTICLE{'name'},$ARTICLE{'author'},$ARTICLE{'price'},$ARTICLE{'pochette'},$ARTICLE{'id_article'},$ARTICLE{'ref_categorie'},$ARTICLE{'article_lieu'})=$c->fetchrow()) {
	my $add3;
	if ($ARTICLE{'ref_categorie'} eq '11') {
		$add3 = $ARTICLE{'article_lieu'};
	}	

	#$string .= " <label>&nbsp;&nbsp;$ARTICLE{'genre'}</label>";
	$string = "<table style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><tr<td align=\"left\" width=\"51\"></td><td align=\"left\" width=\"151\"></td><td align=\"left\"></a></td><td align=\"left\"></td></tr>";
	$i += 1;
	$j += 1;

	if ($i eq 1) {		
		$string .= "<td align=\"left\" width=\"10px\"></td>";
		$i = 0;
	}
	if ($j eq 2) {
		$string .= "</tr>";
		$string .= "<tr>";
		$j = 0;
	}
    }
    $string .= "</table>";    
    return $string;
    
}


sub tableIndexDelivered {
    my $article = $query->param("article");
    my $username = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $depot = $query->param("depot");
    $depot =~ s/[^A-Za-z0-9 ]//;
    
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  ($c)= sqlSelectMany("distinct id_article",
			   "article,a_livre,personne",
			   "ref_article = id_article AND ref_acheteur = id_personne  AND nom_utilisateur = '$username' and a_livre.ref_statut = '10'");	
	
	while( ($ARTICLE{'nom_utilisateur'},$ARTICLE{'question'},$ARTICLE{'texte'},$ARTICLE{'date'})=$c->fetchrow()) {
	    $total +=1;
	}

    my  $nb_page = arrondi ($total / 40, 1);
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
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&page=mybuy&option=mybuydeliveredandbuyed;&amp;min_index=$min_index&amp;max_index=$max_index\"  class=\"menulink2\" ><-$j-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }
        
return $string;    
}

sub loadJardinIndex {
    $lang = $query->param("lang") ;		
    my  $cat = shift || '';
    my  $type = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $depot = $query->param("depot");
    my $subcat = $query->param("subcat");
    my $category = $query->param("category");
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  $add;
    my  $add2;
    my  $dep;
    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");
    my $from;
    my $ref_cat;
    my $ref_subcat;
    if ($category) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $add .= " AND article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
    }
    if ($subcat) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcat' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $add .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
	
    if ($add eq "") {
	$add2 .= " and article.ref_categorie between 92 and 93";
    }	

    my  ($c)= $db->sqlSelect("count(id_article)",
			   "article,met_en_vente,categorie_libelle_langue $from",
			   "ref_article = id_article and article.ref_categorie = categorie_libelle_langue.ref_categorie AND met_en_vente.page_categorie  = 'on' AND ref_statut = '3' AND article.ref_categorie = categorie_libelle_langue.ref_categorie AND  enchere_date_fin > '$date% ' $add $add2");	
	

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
	$string .= "<a href=\"/cgi-bin/h.pl?lang=$lang&amp;page=jardin&session=$session_id&amp;min_index=$min_index&amp;max_index=$max_index&country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=with_lang_french&with_lang_italian=$with_lang_italian&amp;with_lang_german=with_lang_german&with_lang_english=$with_lang_english&category=$category&subcat=$subcat\" ><-$j-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }
    if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }        
return $string;  
}

sub loadInstrumentsByIndex {
	loadLanguage();
    $lang = $query->param("lang") ;		
    my  $cat = shift || '';
    my  $type = shift  || '';
    my  $depot = $query->param("depot") ;
    $depot=~ s/[^A-Za-z0-9 ]//;
    my  $index_start = $query->param ("min_index");
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index");
    $index_end =~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my $category = $query->param("category");
    my $subcat = $query->param("subcategory");
    my $from .= "";
    my  $add = "";
    my $ref_cat;
	loadLanguage();
    my $ref_subcat;
    if ($category) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $add .= " AND article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
    }
    if ($subcat) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcat' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $add .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
    my  $string = "";    my  $add2;
    my  $dep;
    
    if (!$index_start ){$index_start = 0;}
    if (!$index_end ) {$index_end = 40;}
    
    if ($add eq "") {
	$add2 = " and article.ref_categorie between 92 and 93 "
    }
    
            my  ($c)= $db->sqlSelectMany("article.nom,id_article,marque,prix, categorie_libelle_langue.ref_categorie,pochette ",
		       "article,met_en_vente,categorie_libelle_langue, subcategorie_libelle_langue",
		       "ref_article = id_article  AND met_en_vente.notre_selection = '1'  AND ref_statut = '3' AND article.quantite > 0 and article.enchere_date_fin > '$date $time' AND categorie_libelle_langue.ref_categorie = article.ref_categorie AND subcategorie_libelle_langue.ref_subcategorie = article.ref_subcategorie $add  $add2 ORDER BY id_article DESC LIMIT $index_start, $index_end");	
    

    my $i = 0;my $j = 0;
	
    
    $string = "<table style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><tr style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"151\">$SERVER{'article_name_label'}</td><td align=\"left\">$SERVER{'fabricant'}</a></td><td align=\"left\">$SERVER{'article_price_label'}</td></tr>";

    while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'author'},$ARTICLE{'price'},$ARTICLE{'ref_categorie'},$ARTICLE{'image'})=$c->fetchrow()) {
	if ($ARTICLE{'image'} eq '') {
		##$ARTICLE{'image'} = "../images/blank.gif";
	}
        if ($ARTICLE{'ref_categorie'}) {
            $ARTICLE{'genre'} = $db->sqlSelect ("libelle.libelle","categorie_libelle_langue, libelle, langue","categorie_libelle_langue.ref_categorie = '$ARTICLE{'ref_categorie'}' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
        }
        
	$string .= "<tr><td align=\"left\"><img alt=\"\"  src=\"$ARTICLE{'image'}\"></td><td align=\"left\"><a href=\"/cgi-bin/detail.pl?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'author'}</td><td align=\"left\">$ARTICLE{'price'}</td></tr>";
    }
    $string .="</table>";    
    return $string;
    
}
sub loadInstrumentsIndex {
	my $lang = $query->param("lang");
    my  $cat = shift || '';
    my  $type = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $depot = $query->param("depot");
    my $subcat = $query->param("subcategory");
    my $category = $query->param("category");
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  $add;
    my  $add2;
    my  $dep;
    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");
    my $from;
    my $ref_cat;
    my $ref_subcat;
    if ($category) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $add .= " AND article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
    }
    if ($subcat) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcat' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $add .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
	
    if ($add eq "") {
	$add2 .= " and article.ref_categorie between 34 and 35";
    }	

    my  ($c)= $db->sqlSelect("count(id_article)",
			   "article,met_en_vente,categorie_libelle_langue $from",
			   "ref_article = id_article and article.ref_categorie = categorie_libelle_langue.ref_categorie AND met_en_vente.page_categorie  = 'on' AND ref_statut = '3' AND article.ref_categorie = categorie_libelle_langue.ref_categorie AND  enchere_date_fin > '$date% ' $add $add2");	
	

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
	$string .= "<a href=\"/cgi-bin/m.pl?lang=$lang&amp;page=intruments&session=$session_id&amp;min_index=$min_index&amp;max_index=$max_index&country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=with_lang_french&with_lang_italian=$with_lang_italian&amp;with_lang_german=with_lang_german&with_lang_english=$with_lang_english&category=$category&subcat=$subcat\"><-$j-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }
    if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }        
return $string;    
    
}
sub loadWatchIndex {
    $lang = $query->param("lang") ;		
    my  $cat = shift || '';
    my  $type = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $depot = $query->param("depot");
    my $subcat = $query->param("subcat");
    my $category = $query->param("category");
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  $add;
    my  $add2;
    my  $dep;
    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");
    my $from;
    my $ref_cat;
    my $ref_subcat;
    if ($category) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $add .= " AND article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
    }
    if ($subcat) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcat' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $add .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
	
    if ($add eq "") {
	$add2 .= " and article.ref_categorie between 34 and 35";
    }	

    my  ($c)= $db->sqlSelect("count(id_article)",
			   "article,met_en_vente,categorie_libelle_langue $from",
			   "ref_article = id_article and article.ref_categorie = categorie_libelle_langue.ref_categorie AND met_en_vente.page_categorie  = 'on' AND ref_statut = '3' AND article.ref_categorie = categorie_libelle_langue.ref_categorie AND  enchere_date_fin > '$date% ' $add $add2");	
	

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
	$string .= "<a href=\"/cgi-bin/g.pl?lang=$lang&amp;page=watch&session=$session_id&amp;min_index=$min_index&amp;max_index=$max_index&country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=with_lang_french&with_lang_italian=$with_lang_italian&amp;with_lang_german=with_lang_german&with_lang_english=$with_lang_english&category=$category&subcat=$subcat\" ><-$j-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }
    if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }        
return $string;    
}
    

sub loadWatchByIndex {
	loadLanguage();
    $lang = $query->param("lang") ;		
    my  $cat = shift || '';
    my  $type = shift  || '';
    my  $depot = $query->param("depot") ;
    $depot=~ s/[^A-Za-z0-9 ]//;
    my  $index_start = $query->param ("min_index");
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index");
    $index_end =~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my $category = $query->param("category");
    my $subcat = $query->param("subcat");
    my $from .= "";
    my  $add = "";
    my $ref_cat;
    my $ref_subcat;
    if ($category) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $add .= " AND article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
    }
    if ($subcat) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcat' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $add .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
    }
    my  $string = "";    my  $add2;
    my  $dep;
    
    if (!$index_start ){$index_start = 0;}
    if (!$index_end ) {$index_end = 40;}
    
    if ($add eq "") {
	$add2 = " and article.ref_categorie between 34 and 35 "
    }
    
        my  ($c)= $db->sqlSelectMany("DISTINCT(article.nom),id_article,marque,prix, categorie_libelle_langue.ref_categorie,pochette ",
		       "article,met_en_vente,categorie_libelle_langue, subcategorie_libelle_langue",
		       "ref_article = id_article  AND met_en_vente.notre_selection = '1'  AND ref_statut = '3' AND article.quantite > 0 and article.enchere_date_fin > '$date $time' AND categorie_libelle_langue.ref_categorie = article.ref_categorie AND subcategorie_libelle_langue.ref_subcategorie = article.ref_subcategorie $add  $add2 ORDER BY id_article DESC LIMIT $index_start, $index_end");	
    
    my $i = 0;my $j = 0;
	my  $string = "<table style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><tr style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"151\">$SERVER{'article_name_label'}</td><td align=\"left\">$SERVER{'fabricant'}</a></td><td align=\"left\">$SERVER{'article_price_label'}</td></tr>";
    

    
    
    while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'author'},$ARTICLE{'price'},$ARTICLE{'ref_categorie'},$ARTICLE{'image'})=$c->fetchrow()) {
	if ($ARTICLE{'image'} eq '') {
		##$ARTICLE{'image'} = "../images/blank.gif";
	}
        if ($ARTICLE{'ref_categorie'}) {
            $ARTICLE{'genre'} = $db->sqlSelect ("libelle.libelle","categorie_libelle_langue, libelle, langue","categorie_libelle_langue.ref_categorie = '$ARTICLE{'ref_categorie'}' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
        }
        
	$string .= "<tr><td align=\"left\"><img alt=\"\"  src=\"$ARTICLE{'image'}\"></td><td align=\"left\"><a href=\"/cgi-bin/detail.pl?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'author'}</td><td align=\"left\">$ARTICLE{'price'}</td></tr>";
    }
    $string .="</table>";    
    return $string;

}


sub loadJardinByIndex {
	loadLanguage();
    $lang = $query->param("lang") ;		
    my  $cat = shift || '';
    my  $type = shift  || '';
    my  $depot = $query->param("depot") ;
    $depot=~ s/[^A-Za-z0-9 ]//;
    my  $index_start = $query->param ("min_index");
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index");
    $index_end =~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my $category = $query->param("category");
    my $subcat = $query->param("subcat");
    my $from .= "";
    my  $add = "";
    my $ref_cat;
    my $ref_subcat;
    if ($category) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $add .= " AND article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
    }
    if ($subcat) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcat' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $add .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
    my  $string = "";    my  $add2;
    my  $dep;
    
    if (!$index_start ){$index_start = 0;}
    if (!$index_end ) {$index_end = 40;}
    
    if ($add eq "") {
	$add2 = " and article.ref_categorie = 36 "
    }
    
    my  ($c)= $db->sqlSelectMany("DISTINCT article.nom,id_article,marque,prix, categorie_libelle_langue.ref_categorie,pochette ",
		       "met_en_vente, article, categorie_libelle_langue, libelle, langue $from",
		       "ref_article = id_article and article.ref_categorie = categorie_libelle_langue.ref_categorie AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND met_en_vente.page_categorie = 'on' AND ref_statut = '3'  AND  article.ref_categorie = categorie_libelle_langue.ref_categorie AND enchere_date_fin > "." '$date%'  $add $add2 ORDER BY  date_stock DESC LIMIT $index_start, $index_end");	
    
    my $i = 0;my $j = 0;
	$string = "<table style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><tr style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"151\">$SERVER{'article_name_label'}</td><td align=\"left\">$SERVER{'fabricant'}</a></td><td align=\"left\">$SERVER{'article_price_label'}</td></tr>";

    while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'author'},$ARTICLE{'price'},$ARTICLE{'ref_categorie'},$ARTICLE{'image'})=$c->fetchrow()) {
	if ($ARTICLE{'image'} eq '') {
		##$ARTICLE{'image'} = "../images/blank.gif";
	}
        if ($ARTICLE{'ref_categorie'}) {
            $ARTICLE{'genre'} = $db->sqlSelect ("libelle.libelle","categorie_libelle_langue, libelle, langue","categorie_libelle_langue.ref_categorie = '$ARTICLE{'ref_categorie'}' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
        }
        
	$string .= "<tr><td align=\"left\"><img alt=\"\"  src=\"$ARTICLE{'image'}\"></td><td align=\"left\"><a href=\"/cgi-bin/detail.pl?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'author'}</td><td align=\"left\">$ARTICLE{'price'}</td></tr>";
    }
    $string .="</table>";    
    return $string;

}

sub tableByIndexDelivered {

    my $username = shift || '';
    my  $index_start = $query->param ("min_index");
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index");
    $index_end =~ s/[^A-Za-z0-9 ]//;
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

    my  ($c)= sqlSelectMany("DISTINCT id_article,pochette,article.nom,ref_vendeur,condition_payement_libelle_langue.ref_condition_payment,condition_livraison_libelle_langue.ref_condition_livraison, a_livre.quantite,date_reception",
			   "article,personne,a_livre,condition_payement_libelle_langue,condition_livraison_libelle_langue",
			   "ref_article = id_article AND ref_acheteur = id_personne  AND nom_utilisateur = '$username' and a_livre.ref_statut = '10' AND ref_condition_payement = id_condition_payement AND  ref_condition_livraison  =  id_condition_livraison LIMIT $index_start, $index_end");	
    

    my $i = 0;
    my $j = 0;
    my $condition_payment;
    my $condition_livraison;

    $string = "<table style=\"border-width:thin; border-style:dotted; border-top-color:#94CEFA;border-right-color:#94CEFA;border-left-color:#94CEFA; border-bottom-color:#94CEFA\" width=\"555\" border=\"0\"><tr bgcolor=\"#DBE4F8\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"151\">$SERVER{'article_name_label'}</td><td align=\"left\">Vendeur</td><td align=\"left\">$SERVER{'article_quantity_label'}</td><td>$SERVER{'date_reception'}</td></tr>";
    while( ($ARTICLE{'id_article'},$ARTICLE{'pochette'}, $ARTICLE{'name'},$ARTICLE{'ref_vendeur'},$ARTICLE{'payement_mode'},$ARTICLE{'deliver_mode'},$ARTICLE{'quantity'},$ARTICLE{'date_reception'})=$c->fetchrow()) {
	#$string .= " <label>&nbsp;&nbsp;$ARTICLE{'genre'}</label>";
	my ($vendeur_username,$vendeur_name,$vendeur_firstname,$vendeur_adresse,$condition_payment_ref,$condition_livraison_ref)= sqlSelect("nom_utilisateur,nom,prenom,adresse,ville,npa", "personne","id_personne = '$ARTICLE{'ref_vendeur'}'");
	if ($ARTICLE{'pochette'} eq '') {
		$ARTICLE{'pochette'} = "../images/no.gif";
	}
	if ($ARTICLE{'payement_mode'} ne '') {
		$condition_payment = sqlSelect ("libelle.libelle","condition_payment_libelle_langue, libelle, langue", "condition_payement_libelle_langue.ref_condition_payment = '$ARTICLE{'payement_mode'}' AND condition_payement_libelle_langue.ref_libelle = libelle.id_libelle AND condition_payement_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
	}
	if ($ARTICLE{'deliver_mode'} ne '') {
		$condition_livraison = sqlSelect ("libelle.libelle","condition_livraison_libelle_langue, libelle, langue", "condition_livraison_libelle_langue.ref_condition_livraison = '$ARTICLE{'deliver_mode'}' AND condition_livraison_libelle_langue.ref_libelle = libelle.id_libelle AND condition_livraison_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
	}
	
	$string .= "<tr><td align=\"left\"><img alt=\"\" src=\"$ARTICLE{'pochette'}\" alt=\"\"/></td><td align=\"left\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&amp;action=detailother&amp;article=$ARTICLE{'id_article'}\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$vendeur_username</td><td>$ARTICLE{'quantity'}</td><td>$ARTICLE{'date_reception'}</td><td align=\"left\"><a href=\"javascript:void(0)\" class=\"menulink\"  onclick=\"window.open('/cgi-bin/recordz.cgi?lang=$lang&amp;page=evalproduct&amp;session=$session_id&article=$ARTICLE{'id_article'}&buyer=$username;','MyWindow','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=no,width=800,height=300,left=20,top=20')\">Evaluez le produit</a></td></tr>";
	#$string .= "<td align=\"left\" width=\"300px\" style=\"border-style:dotted;border-width:thin;border-color:#94CEFA\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&amp;action=detailother&amp;article=$ARTICLE{'id_article'}\" class=\"menulink\" >$ARTICLE{'name'}</a><br/><img alt=\"\" src=\"$ARTICLE{'pochette'}\" alt=\"\"/><br/>$ARTICLE{'author'}<br/>$ARTICLE{'montant'} <br/>$ARTICLE{'date_stock'} Vendeur : $vendeur_username <br/>Pr�nom et nom : $vendeur_firstname $vendeur_name <br/>Ville : $vendeur_city<br /> Mode de payement : $ARTICLE{'payement_mode'}<br /> Livraison : $ARTICLE{'deliver_mode'} <br/><a href=\"javascript:void(0)\" class=\"menulink\"  onclick=\"window.open('/cgi-bin/recordz.cgi?lang=$lang&amp;page=evalproduct&amp;session=$session_id&article=$ARTICLE{'id_article'}&buyer=$username;','MyWindow','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=no,width=800,height=300,left=20,top=20')\">Evaluez le produit</a></td>";
	$i += 1;
	$j += 1;

	if ($i eq 1) {		
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

    
sub loadImmobilierIndex {
    $lang = $query->param("lang") ;		
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
    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");
    my  $add2;
    
    my $ref_cat;
    my $ref_subcat;
    my $country = $query->param("country_name");
    my $location_type = $query->param("location_type");
    my $canton = $query->param("canton");
    my $departement = $query->param("departement");
    my $subcategory = $query->param("subcategory");
    my $location_ou_achat = $query->param("location_ou_achat");
    if ($subcategory) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcategory' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $add .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
    if ($country eq 'Suisse') {
	$add .= " and article.ref_pays = 1";
    } elsif ($country eq 'France') {
	$add .= " and article.ref_pays = 2";
    }
    $lang = lc($lang);
    if ($canton) {
	$add .= " and article.ref_canton = (SELECT id_canton FROM canton_$lang WHERE nom = '$canton')";
    }
    if ($departement) {
	$add .= " and article.ref_departement = (SELECT id_departement FROM departement WHERE nom = '$departement')";
    }
    if ($location_ou_achat) {
	$add .= " and article.ref_location_ou_achat = (SELECT ref_location_ou_achat FROM location_ou_achat_libelle_langue, libelle, langue WHERE libelle.libelle = '$location_ou_achat' AND location_ou_achat_libelle_langue.ref_libelle = libelle.id_libelle AND location_ou_achat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
    }
    if ($add eq "") {
	$add2 .= " AND article.ref_categorie = 25";
    }	


    my  ($c)= $db->sqlSelect("count(id_article)",
			   "article,met_en_vente $from",
			   "ref_article = id_article AND met_en_vente.ref_article = article.id_article AND ref_statut = '3' AND  enchere_date_fin > '$date% ' AND quantite > 0 $add $add2");	
	
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
	$string .= "<a href=\"/cgi-bin/immo.pllang=$lang&amp;page=immo&amp;session=$session_id&amp;min_index=$min_index&amp;max_index=$max_index&amp;country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=with_lang_french&amp;with_lang_italian=$with_lang_italian&amp;with_lang_german=with_lang_german&amp;with_lang_english=$with_lang_english\" ><-$j-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }
    if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }        
return $string;    
}


sub loadImmobilierByIndex {
	loadLanguage();
    $lang = $query->param("lang") ;		
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
    my  $add = "";
    my $from;
    my  $add2;
    my $ref_cat;
    my $ref_subcat;
    my $country = $query->param("country_name");
    my $location_type = $query->param("location_type");
    my $canton = $query->param("canton");
    my $departement = $query->param("departement");
    my $subcategory = $query->param("subcategory");
    my $location_ou_achat = $query->param("location_ou_achat");
    if ($subcategory) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcategory' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $add .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
    if ($country eq 'Suisse') {
	$add .= " and article.ref_pays = 1";
    } elsif ($country eq 'France') {
	$add .= " and article.ref_pays = 2";
    }
    $lang = lc($lang);
    if ($canton) {
	$add .= " and article.ref_canton = (SELECT id_canton FROM canton_$lang WHERE nom = '$canton')";
    }
    if ($departement) {
	$add .= " and article.ref_departement = (SELECT id_departement FROM departement WHERE nom = '$departement')";
    }
    if ($location_ou_achat) {
	$add .= " and article.ref_location_ou_achat = (SELECT ref_location_ou_achat FROM location_ou_achat_libelle_langue, libelle, langue WHERE libelle.libelle = '$location_ou_achat' AND location_ou_achat_libelle_langue.ref_libelle = libelle.id_libelle AND location_ou_achat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
    }
    if ($add eq "") {
	$add2 .= " AND article.ref_categorie = 25";
    }	
    
    if (!$index_start ) {$index_start = 0;}
    if (!$index_end ) {$index_end = 40;}

   

        my  ($c)= $db->sqlSelectMany("article.nom,id_article,marque,prix, categorie_libelle_langue.ref_categorie,pochette ",
		       "article,met_en_vente,categorie_libelle_langue, subcategorie_libelle_langue",
		       "ref_article = id_article  AND met_en_vente.notre_selection = '1'  AND ref_statut = '3' AND article.quantite > 0 and article.enchere_date_fin > '$date $time' AND categorie_libelle_langue.ref_categorie = article.ref_categorie AND subcategorie_libelle_langue.ref_subcategorie = article.ref_subcategorie $add  $add2 ORDER BY id_article DESC LIMIT $index_start, $index_end");	
    my $i = 0;my $j = 0;
	    $string = "<table style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><tr style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"151\">$SERVER{'article_name_label'}</td><td align=\"left\">$SERVER{'fabricant'}</a></td><td align=\"left\">$SERVER{'article_price_label'}</td></tr>";
    
        while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'author'},$ARTICLE{'price'},$ARTICLE{'ref_categorie'},$ARTICLE{'image'})=$c->fetchrow()) {
	if ($ARTICLE{'image'} eq '') {
		##$ARTICLE{'image'} = "../images/blank.gif";
	}
        if ($ARTICLE{'ref_categorie'}) {
            $ARTICLE{'genre'} = $db->sqlSelect ("libelle.libelle","categorie_libelle_langue, libelle, langue","categorie_libelle_langue.ref_categorie = '$ARTICLE{'ref_categorie'}' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
        }
        
	$string .= "<tr><td align=\"left\"><img alt=\"\"  src=\"$ARTICLE{'image'}\"></td><td align=\"left\"><a href=\"/cgi-bin/detail.pl?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'author'}</td><td align=\"left\">$ARTICLE{'price'}</td></tr>";
    }
    $string .="</table>";    
    return $string;
  
}
    
sub tableIndexEffect {
    my $article = $query->param("article");
    my $username = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $depot = $query->param("depot");
    $depot =~ s/[^A-Za-z0-9 ]//;
    
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  ($c)= sqlSelectMany("distinct id_article",
			   "article,met_en_vente,personne,a_livre",
			   "a_livre.ref_article = id_article AND a_livre.ref_vendeur = id_personne  AND nom_utilisateur = '$username' and a_livre.ref_statut = '10'");	
	
	while( ($ARTICLE{'nom_utilisateur'},$ARTICLE{'question'},$ARTICLE{'texte'},$ARTICLE{'date'})=$c->fetchrow()) {
	    $total +=1;
	}

    my  $nb_page = arrondi ($total / 40, 1);
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
    if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }        
return $string;    
}


sub tableByIndexEffect {

    my $username = shift || '';
    my  $index_start = $query->param ("min_index");
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index");
    $index_end =~ s/[^A-Za-z0-9 ]//;
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

    my  ($c)= sqlSelectMany("pochette,article.nom,id_article,a_livre.ref_acheteur,a_livre.montant,a_livre.quantite",
			   "article,personne,a_livre",
			   "a_livre.ref_article = id_article AND a_livre.ref_vendeur = id_personne  AND nom_utilisateur = '$username' and a_livre.ref_statut = '10' LIMIT $index_start, $index_end");	
    
    
    my $i = 0;
    my $j = 0;
    $string = "<table style=\"border-width:thin; border-style:dotted; border-top-color:#94CEFA;border-right-color:#94CEFA;border-left-color:#94CEFA; border-bottom-color:#94CEFA\" width=\"555\" border=\"0\"><tr bgcolor=\"#DBE4F8\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"151\">$SERVER{'article_name_label'}</td><td>$SERVER{'buyer'}</td><td align=\"left\">$SERVER{'article_price_label'}</td><td align=\"left\">$SERVER{'article_quantity_label'}</td></tr>";
    while( ($ARTICLE{'pochette'}, $ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'ref_acheteur'},$ARTICLE{'montant'},$ARTICLE{'quantite'})=$c->fetchrow()) {
	#$string .= " <label>&nbsp;&nbsp;$ARTICLE{'genre'}</label>";
	my  ($acheteur)= sqlSelect("nom_utilisateur", "personne","id_personne = $ARTICLE{'ref_acheteur'}");	    
	if ($ARTICLE{'pochette'} eq '') {
		$ARTICLE{'pochette'} = "../images/no.gif";
	}
	$ARTICLE{'label'} = substr($ARTICLE{'label'},0, 18);
	$ARTICLE{'label'} .= "...";
	$string .= "<tr><td align=\"left\"><img alt=\"\" src=\"$ARTICLE{'pochette'}\" alt=\"\"/></td><td align=\"left\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&amp;action=detailother&amp;article=$ARTICLE{'id_article'}\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$acheteur</td><td align=\"left\">$ARTICLE{'montant'}</td><td align=\"left\">$ARTICLE{'quantite'}</td></tr>";
	$i += 1;
	$j += 1;

	if ($i eq 1) {		
		$string .= "<td align=\"left\" width=\"10px\"></td>";
		$i = 0;
	}
	if ($j eq 2) {
		$string .= "</tr>";
		$string .= "<tr>";
		$string .= "</tr>";
		
		$string .= "</tr>";
		$string .= "<tr>";

		$j = 0;
	}
    }
    $string .= "</table>";
    return $string;
        
}
    


sub viewArticleLastHourByIndex {
    loadLanguage();
    my  $cat = shift || '';
    my  $type = shift  || '';
    my  $depot = $query->param("depot") ;
    $depot=~ s/[^A-Za-z0-9 ]//;
    my  $index_start = $query->param ("min_index_last_hour");
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index_last_hour");
    $index_end =~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d",$hour);
    $date = trimwhitespace($date);
    $time = trimwhitespace($time);
    my  $string = "";
    my  $add;
    my  $add2;
    my  $dep;
    if ($time eq '0' or $time eq '1' or $time eq '2' or $time eq '3' or $time eq '4' or $time eq '5' or $time eq '6' or $time eq '7' or $time eq '8' or $time eq '9') {
	$time = "0" .$time;
    }

    if (!$index_start ) {
	$index_start = 0;
    }
    if (!$index_end ) {
	$index_end = 40;
    }

    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");

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
    $add .= getAdd();
    my  ($c)= sqlSelectMany("DISTINCT article.nom,marque,prix, pochette,id_article,date_stock,ref_categorie,article.lieu",
		       "article,met_en_vente",
		       "ref_article = id_article  AND  ref_statut = '3' AND quantite > 0 enchere_date_fin like '$date $time%' $add LIMIT $index_start, $index_end ORDER BY id_article DESC");
    my $i = 0;my $j = 0;
    my $string = "<table style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><tr style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"151\">$SERVER{'article_name_label'}</td><td align=\"left\">$SERVER{'fabricant'}</a></td><td align=\"left\">$SERVER{'article_price_label'}</td></tr>";
    
    while( ($ARTICLE{'name'},$ARTICLE{'author'},$ARTICLE{'price'},$ARTICLE{'pochette'},$ARTICLE{'id_article'},$ARTICLE{'date'},$ARTICLE{'ref_categorie'},$ARTICLE{'article_lieu'})=$c->fetchrow()) {
	if ($ARTICLE{'name'}) {
	if ($ARTICLE{'pochette'} eq '') {$ARTICLE{'pochette'} = "../images/no.gif";}
	my $add3;my $img;	if ($ARTICLE{'ref_categorie'} eq '11') {$add3 = $ARTICLE{'article_lieu'};}
	if ($ARTICLE{'date'} eq $date) {$img = "../images/new_article.gif"}else {}
	$string .= "<td align=\"left\" width=\"250px\" height=\"100px\" style=\"border-style:dotted;background-image:url(../images/test2.gif);background-position:right bottom;background-repeat: no-repeat; border-width:thin;border-top-style:dashed;border-top-width:medium;border-color:#94CEFA\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&amp;action=detailother&amp;article=$ARTICLE{'id_article'}\" class=\"menulink\" >$ARTICLE{'name'}</a><br/><img alt=\"\" src=\"$ARTICLE{'pochette'}\" $add3 /> <img alt=\"\" src=\"$img\" alt=\"\"/><br/>$ARTICLE{'price'} CHF CHF<br/><br/></td>";
	$i += 1;$j += 1;
	if ($i eq 1) {$string .= "<td align=\"left\" width=\"10px\"></td>";$i = 0;}
	if ($j eq 2) {$string .= "</tr>";$string .= "<tr>";$j = 0;}
	}else {
		$string = "";
	}
    }#fin while
    $string .= "</tr></table>" if ($string ne '');
    
    return $string;
    
}

sub viewARTICLEOnlyEnchhopIndex {
	$lang = $query->param("lang");
    my  $cat = shift || '';
    my  $type = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d",$hour);
    my  $depot = $query->param("depot");
    $depot =~ s/[^A-Za-z0-9 ]//;
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  $add;

    my  $add2;
    my  $dep;
    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");


    my  ($c)=$db->sqlSelect("count(article.nom)",
			   "article",
			   "enchere_date_fin > '$date%' AND ref_statut = '3' AND enchere = '1' $add and quantite > 0");	
	

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
	$string .= "<a href=\"/cgi-bin/main.pl?min_index=0&max_index=40&index_page=1&page=main&amp;lang=$lang&amp;page=main&amp;saw=onlyench&lang=$lang&amp;session=$session_id&amp;min_index_last_hour=$min_index&amp;max_index_last_hour=$max_index&amp;country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=$with_lang_french&amp;with_lang_german=$with_lang_german&amp;with_lang_italian=$with_lang_italian&amp;with_lang_english=$with_lang_english\" ><-$j-></a>&#160;&nbsp;";		
	$min_index += 4;	
    }
    if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }        
return $string;    
}

sub viewARTICLEFromShopIndex {
    my $lang = $query->param("lang");	
    my  $cat = shift || '';
    my  $type = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d",$hour);
    my  $depot = $query->param("depot");
    $depot =~ s/[^A-Za-z0-9 ]//;
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  $add;

    my  $add2;
    my  $dep;
    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");


    my  ($c)=$db->sqlSelect("count(article.nom)",
			   "article",
			   "enchere_date_fin > '$date $time%' AND ref_statut = '3' AND article.enchere = 0 $add and article.ref_etat = 2");	
	

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
	$string .= "<a href=\"/cgi-bin/recordz.cgi?page=main&saw=onlynew&lang=$lang&amp;session=$session_id&amp;min_index_last_hour=$min_index&amp;max_index_last_hour=$max_index&amp;country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=$with_lang_french&amp;with_lang_german=$with_lang_german&amp;with_lang_italian=$with_lang_italian&amp;with_lang_english=$with_lang_english\"  ><-$j-></a>&#160;&nbsp;";		
	$min_index += 4;	
    }
    if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }        
return $string;    
    
}

sub loadARTICLEFromShopByIndex {
    my  $cat = shift || '';
	$lang = $query->param("lang");
    my  $type = shift  || '';
    my  $depot = $query->param("depot") ;
    $depot=~ s/[^A-Za-z0-9 ]//;
    my  $index_start = $query->param ("min_index_last_hour");
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index_last_hour");
    $index_end =~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d",$hour);
    $date = trimwhitespace($date);
    $time = trimwhitespace($time);
	loadLanguage();
    my  $string = "";
    my  $add;
    my  $add2;
    my  $dep;
    if ($time eq '0' or $time eq '1' or $time eq '2' or $time eq '3' or $time eq '4' or $time eq '5' or $time eq '6' or $time eq '7' or $time eq '8' or $time eq '9') {
	$time = "0" .$time;
    }

    if (!$index_start ) {
	$index_start = 0;
    }
    if (!$index_end ) {
	$index_end = 40;
    }

        my  ($c)= $db->sqlSelectMany("article.nom,id_article,marque,prix, categorie_libelle_langue.ref_categorie,pochette ",
		       "article,met_en_vente,categorie_libelle_langue",
		       "ref_article = id_article  AND met_en_vente.notre_selection = '1'  AND ref_statut = '3' AND article.enchere = 0  AND article.quantite > 0 and article.enchere_date_fin > '$date $time' AND categorie_libelle_langue.ref_categorie = article.ref_categorie $add  ORDER BY id_article DESC LIMIT $index_start, $index_end");	
    
    my $i = 0;
    my $j = 0;
 

	$string = "<table style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><tr style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"151\">$SERVER{'article_name_label'}</td><td align=\"left\">$SERVER{'fabricant'}</a></td><td align=\"left\">$SERVER{'article_price_label'}</td></tr>";
    

    
    
    while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'author'},$ARTICLE{'price'},$ARTICLE{'ref_categorie'},$ARTICLE{'image'})=$c->fetchrow()) {
	if ($ARTICLE{'image'} eq '') {
		##$ARTICLE{'image'} = "../images/blank.gif";
	}
        if ($ARTICLE{'ref_categorie'}) {
            $ARTICLE{'genre'} = $db->sqlSelect ("libelle.libelle","categorie_libelle_langue, libelle, langue","categorie_libelle_langue.ref_categorie = '$ARTICLE{'ref_categorie'}' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
        }
        
	$string .= "<tr><td align=\"left\"><img alt=\"\"  src=\"$ARTICLE{'image'}\"></td><td align=\"left\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'author'}</td><td align=\"left\">$ARTICLE{'price'}</td></tr>";
    }
    $string .="</table>";    
    return $string;

}
sub loadARTICLEOnlyEnchByIndex {
    my  $cat = shift || '';
	loadLanguage();
    my  $type = shift  || '';
	$lang = $query->param("lang");
    my  $depot = $query->param("depot") ;
    $depot=~ s/[^A-Za-z0-9 ]//;
    my  $index_start = $query->param ("min_index_last_hour");
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index_last_hour");
    $index_end =~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d",$hour);
    $date = trimwhitespace($date);
    $time = trimwhitespace($time);
    my  $string = "";
    my  $add;
    my  $add2;
    my  $dep;
    if ($time eq '0' or $time eq '1' or $time eq '2' or $time eq '3' or $time eq '4' or $time eq '5' or $time eq '6' or $time eq '7' or $time eq '8' or $time eq '9') {
	$time = "0" .$time;
    }

    if (!$index_start ) {
	$index_start = 0;
    }
    if (!$index_end ) {
	$index_end = 40;
    }

    my  ($c)= $db->sqlSelectMany("article.nom,id_article,marque,prix, categorie_libelle_langue.ref_categorie,pochette ",
		       "article,met_en_vente,categorie_libelle_langue",
		       "ref_article = id_article  AND met_en_vente.notre_selection = '1' AND ref_statut = '3' AND article.enchere = 1  AND article.quantite > 0 and article.enchere_date_fin > '$date%' AND categorie_libelle_langue.ref_categorie = article.ref_categorie $add  ORDER BY id_article DESC LIMIT $index_start, $index_end");	
    
    my $i = 0;
    my $j = 0;
 

  my $string = "<table style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><tr style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"151\">$SERVER{'article_name_label'}</td><td align=\"left\">$SERVER{'fabricant'}</a></td><td align=\"left\">$SERVER{'article_price_label'}</td></tr>";
    

    
    
    while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'author'},$ARTICLE{'price'},$ARTICLE{'ref_categorie'},$ARTICLE{'image'})=$c->fetchrow()) {
	if ($ARTICLE{'image'} eq '') {
		##$ARTICLE{'image'} = "../images/blank.gif";
	}
        if ($ARTICLE{'ref_categorie'}) {
            $ARTICLE{'genre'} = $db->sqlSelect ("libelle.libelle","categorie_libelle_langue, libelle, langue","categorie_libelle_langue.ref_categorie = '$ARTICLE{'ref_categorie'}' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
        }
        
	$string .= "<tr><td align=\"left\"><img alt=\"\"  src=\"$ARTICLE{'image'}\"></td><td align=\"left\"><a href=\"/cgi-bin/detail.pl?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'author'}</td><td align=\"left\">$ARTICLE{'price'}</td></tr>";
    }
    $string .="</table>";    
    return $string;
}

sub loadARTICLELastHour {
    my  $cat = shift || '';
    my  $type = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d",$hour);
    my  $depot = $query->param("depot");
    $depot =~ s/[^A-Za-z0-9 ]//;
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  $add;
    $date = trimwhitespace($date);
    $time = trimwhitespace($time);
    if ($time eq '0' or $time eq '1' or $time eq '2' or $time eq '3' or $time eq '4' or $time eq '5' or $time eq '6' or $time eq '7' or $time eq '8' or $time eq '9') {
	$time = "0" .$time;
    }

    my  $add2;
    my  $dep;
    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");

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
	
    

    my  ($c)= $db->sqlSelect("count(article.nom)",
			   "article",
			   "enchere_date_fin like '$date $time%' AND quantite > 0 AND ref_statut = '3' $add");	
	

    my  $nb_page = arrondi ($c / 4, 1);
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
	$string .= "<a href=\"/cgi-bin/recordz.cgi?page=main&lang=$lang&amp;session=$session_id&amp;min_index_last_hour=$min_index&amp;max_index_last_hour=$max_index&amp;country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=$with_lang_french&amp;with_lang_german=$with_lang_german&amp;with_lang_italian=$with_lang_italian&amp;with_lang_english=$with_lang_english&saw=lasthour\" ><-$j-></a>&#160;&nbsp;";		
	$min_index += 4;	
    }
    if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }        
return $string;    
}

sub viewARTICLELastHourByIndex {
       my  $cat = shift || '';
    my  $type = shift  || '';
    my  $depot = $query->param("depot") ;
    $depot=~ s/[^A-Za-z0-9 ]//;
    my  $index_start = $query->param ("min_index_last_hour");
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index_last_hour");
    $index_end =~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d",$hour);
    $date = trimwhitespace($date);
    $time = trimwhitespace($time);
	loadLanguage();
    my  $string = "";
    my  $add;
    my  $add2;
    my  $dep;
    if ($time eq '0' or $time eq '1' or $time eq '2' or $time eq '3' or $time eq '4' or $time eq '5' or $time eq '6' or $time eq '7' or $time eq '8' or $time eq '9') {
	$time = "0" .$time;
    }

    if (!$index_start ) {
	$index_start = 0;
    }
    if (!$index_end ) {
	$index_end = 40;
    }

    my $country_swiss = $query->param("country_swiss");
    my $country_france = $query->param("country_france");
    my $with_lang_french = $query->param("with_lang_french");
    my $with_lang_german = $query->param("with_lang_german");
    my $with_lang_italian = $query->param("with_lang_italian");
    my $with_lang_english = $query->param("with_lang_english");

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
  
    my  ($c)= $db->sqlSelectMany("article.nom,id_article,marque,prix, categorie_libelle_langue.ref_categorie,pochette ",
		       "article,met_en_vente,categorie_libelle_langue",
		       "ref_article = id_article  AND met_en_vente.notre_selection = '1' AND ref_statut = '3' and met_en_vente.page_principale = 'on' AND article.quantite > 0 and article.enchere_date_fin like '$date $time' AND categorie_libelle_langue.ref_categorie = article.ref_categorie $add  ORDER BY id_article DESC LIMIT $index_start, $index_end");	
    my $i = 0;my $j = 0;
    $string = "<table style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><tr style=\"border-radius: 25px;border: 2px solid #6100C1;padding: 20px;\" width=\"555\" border=\"0\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"151\">$SERVER{'article_name_label'}</td><td align=\"left\">$SERVER{'fabricant'}</a></td><td align=\"left\">$SERVER{'article_price_label'}</td></tr>";
    
    while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'author'},$ARTICLE{'price'},$ARTICLE{'ref_categorie'},$ARTICLE{'image'})=$c->fetchrow()) {
	if ($ARTICLE{'image'} eq '') {
		##$ARTICLE{'image'} = "../images/blank.gif";
	}
        if ($ARTICLE{'ref_categorie'}) {
            $ARTICLE{'genre'} = $db->sqlSelect ("libelle.libelle","categorie_libelle_langue, libelle, langue","categorie_libelle_langue.ref_categorie = '$ARTICLE{'ref_categorie'}' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
        }
        
	$string .= "<tr><td align=\"left\"><img alt=\"\"  src=\"$ARTICLE{'image'}\"></td><td align=\"left\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'author'}</td><td align=\"left\">$ARTICLE{'price'}</td></tr>";
    }
    $string .="</table>";    
    return $string;
}
BEGIN {
    use Exporter ();
  
    @TableArticle::ISA = qw(Exporter);
    @TableArticle::EXPORT  = qw();
    @TableArticle::EXPORT_OK   =  qw (loadGamesByIndex () loadArticleLastHour () loadSportIndex() loadSportByIndex()  loadDvdIndex () loadDvdByIndex sub loadBabyIndex () loadBabyByIndex() loadAstroByIndex () loadEvalDealPositivIndex () loadEvalDealPositivTable () loadEvalBuyPositivIndex () loadEvalBuyNegativIndex () loadEvalBuyNegativTable ()  loadInformatiqueIndex () loadInformatiqueByIndex () viewAutoNewsByIndex () viewTvNewsByIndex () loadWearIndex () loadArticleOnlyEnchIndex () loadWearByIndex () loadCommandIndex () loadCommandByIndex () loadCommandDetailIndex () loadCommandDetailByIndex () viewArticleNewsByIndex () loadArticleFromShopByIndex () loadArticleOnlyEnchByIndex () loadViewArticleFromShopIndex ()  viewArticleOnlyEnchShopIndex () loadLingerieIndex () loadLingerieByIndex () loadInstrumentIndex ()  loadInstrumentByIndex () loadHabitatJardinIndex () loadHabitatJardinByIndex () loadCollectionIndex () loadCollectionByIndex () loadCharityIndex () loadCharityByIndex () loadMotoIndex () loadMotoByIndex () loadBoatIndex () loadBoatByIndex () loadChocolatIndex () loadChocolatByIndex () loadParfumIndex () loadParfumByIndex () loadCaviarIndex () loadCaviarByIndex () loadCdVinylMixTapeIndex () loadCdVinylMixTapeByIndex () loadWineIndex () loadWineByIndex () loadTableIndexMyBuyToBuy () loadTableByIndexMyBuyToBuy () loadTableByIndexDelivered () loadTableIndexMyBuyToBuyWaiting () loadTableByIndexMyBuyToBuyWaiting ()  loadTableIndexMyBuyBuyWaiting ()  loadTableIndexMyBuyToBuyWaiting () loadTableByIndexMyBuyBuyWaiting ()  loadTableIndexSoulevement () loadTableByIndexSoulevement () loadIndexEffect () loadTableByIndexEffect () loadTableIndexMyBuyWaiting () loadTableIndexMyBuyWaiting () loadTableByIndexMyBuyWaiting ()  loadTableIndexCurrentDeal () loadTableByIndexCurrentDeal () loadTableIndexInvendu ()  loadTableIndexToDeliver () loadTableByIndexToDeliver () loadTableByIndexInvendu () doBestOfferIndex ()  doBestOfferIndexed ()  evalArticleIndex ()  evalArticleTable () loadEvalDealNegativIndex () loadEvalDealNegativTable () loadInformatiqueIndex ()  loadInformatiqueByIndex () viewAutoNewsByIndex () viewTvNewsByIndex () viewArticleNewsByIndex () loadArticleFromShopByIndex () viewArticleOnlyEnchShopIndex () viewArticleLastHourByIndex () viewArticleSelectionByIndex () loadCalendrierIndex () loadCalendrierByIndex() loadGamesIndex () loadAstroIndex () loadAstroByIndex ());  
  }
1;