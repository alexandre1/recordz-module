#!"C:\xampp\perl\bin\perl.exe"
package Search;
use warnings;
use MyDB;
use LoadProperties;
use Time::HiRes qw(gettimeofday);

our $db = MyDB->new();
our $lp = LoadProperties->create();
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
sub new {
        my $class = shift;
        my ($opts)= @_;
	my $self = {};
        
	return bless $self, $class;
}

sub search {
    my  $article = $query->param ('search_name');
    my $index = doSearch();
    my $table = doSearchIndexed($article);
    open (FILE, "<$dir/search.html") or die "cannot open file $dir/search.html";
    my $categories = $lp->loadCategories();
	my $menu = $lp->loadMenu();
	my $content;
	$LINK{'add_deal'} .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=add_deal&session=$session_id;\" class=\"menulink\" class=&{ns4class};>$SERVER{'vinyl_add_one'}</a>";
	while (<FILE>) {	
	    s/\$LABEL\{'([\w]+)'\}/ exists $SERVER{$1} ? $SERVER{$1} : $1 /eg; 
	    s/\$LANG/$lang/g;
	    s/\$ERROR\{'([\w]+)'\}/ exists $ERROR{$1} ? $ERROR{$1} : $1 /eg; 
	    s/\$OPTIONS\{'categories'\}/$categories/g;
	    s/\$ARTICLE{'main_menu'}/$menu/g;
	    s/\$ARTICLE{'index_table'}/$index/g;
	    s/\$ARTICLE{'table'}/$table/g;
	    s/\$LINK{'add_deal'}/$LINK{'add_deal'}/g;
	    s/\$SESSIONID/$session_id/g;
	    $content .= $_;	
        }

	$content = Compress::Zlib::memGzip($content)  if $can_do_gzip; ;
	print "Content-Length: ", length($content) , "\n";
	print "Content-Encoding: gzip\n" ;
	print "Content-Type: text/html\n\n"; 
	print $content;
	#print "client :" .$client;
        close (FILE);
}
sub doSearch {
   my  $article = $query->param ('search_name');
   $article =~ s/[^\w]//g; 
   my $category = $query->param("categories");
   #$category =~ s/[^\w]//g; 
    
    my  $string = "";
    my $add;
    my  $select = "DISTINCT article.nom";
    my  $from ;
    my  $where;
    my $test = $SERVER{'all_categories'};
    $category = trimwhitespace($category);
    $test = trimwhitespace($test);
    if ($category ne $test) {
	$add  .= "AND article.ref_categorie = categorie_libelle_langue.ref_categorie AND libelle.libelle = '$category' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'";
	$from .= "article,categorie_libelle_langue, libelle, langue";
    }else {
	#$category = '';
	$from .= "article";
    }

    my  $total = '0';
    my $username = $query->param("username");
    my  ($cat)= $db->sqlSelect("ref_categorie", "categorie_libelle_langue, libelle, langue", "libelle.libelle = '$category' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my  ($userID)= $db->sqlSelect("id_personne", "personne", "nom_utilisateur = '$username'");
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d",$year+1900,$mon+1,$mday;
    
    my  ($d)= $db->sqlSelect("count(article.nom)", $from, "article.nom like '%$article%' AND ref_statut = '3' $add");
    my  $nb_page = arrondi ($d / 40, 1);
    my  $min_index = '0';
    my  $max_index = '40';

    for (my  $i = '0'; $i < $nb_page;$i++) {
	my $n2 = $i %= 10;
	if ($n2 ne '0') {
		#$string .= "<br />";
	}
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=search&amp;min_index=$min_index&max_index=$max_index&amp;search_name=$article&amp;$session_id&amp;categories=$category\"  class=\"menulink2\" ><-$i-></a>&#160;&nbsp;<img alt=\"\" alt=\"\" src=\"../images/next2.gif\" height=\"13px\" width=\"13px\">";		
	$min_index += 40;	
    }
    return $string;
}
#load search index result
sub doSearchIndexed {
    my $call = shift || '';
    my  $article = $query->param ('search_name');
    $article=~ s/\'/\'\'/g;
    my  $article_genre = shift || '';
    my  $artist = shift || '';
    my  $depot = $query->param("depot");
    $depot =~ s/[^\w]//g;
    my $category = $query->param("categories");
    $category =~ s/\W,//g;
    my  $index_start = $query->param ("min_index");if ($index_start =~ m/^[0-9]/) {$index_start = $query->param ('min_index');}else {$index_start = "";}
    my  $index_end = $query->param ("max_index") ;if ($index_end =~ m/^[0-9]/) {$index_end = $query->param ('max_index');}else {$index_end = "";}
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d",$year+1900,$mon+1,$mday;
    my $add;
    $category = trimwhitespace($category);
    my $test = $SERVER{'all_categories'};
    $test = trimwhitespace($test);
    my  $from ;
    if ($category ne $test) {
        $from .= "article, categorie_libelle_langue, libelle, langue";
	$add  .= " AND categorie_libelle_langue.ref_categorie = article.ref_categorie AND categorie_libelle_langue.ref_categorie = (SELECT categorie_libelle_langue.ref_categorie FROM categorie_libelle_langue, libelle, langue WHERE libelle.libelle = '$category' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
        #$from .= "article, categorie_libelle_langue ,statut_libelle_langue";
    }else {
        $add  .= " AND article.ref_statut = id_statut AND article.ref_categorie = id_categorie";
        $from .= "article, statut_libelle_langue, categorie_libelle_langue";
    }
    
    if (!$index_start ) {$index_start = 0;}
    if (!$index_end ) {$index_end = 40;}
    my  $select = "DISTINCT article.nom, id_article, marque, prix, categorie_libelle_langue.ref_categorie, pochette";
    my  $where;
    my  $string = "<table style=\"border-width:thin; border-style:dotted;border-top-color:#94CEFA;border-right-color:#94CEFA;border-left-color:#94CEFA; border-right-width:2px; border-bottom-color:#94CEFA\" width=\"555\" border=\"0\"><tr bgcolor=\"#DBE4F8\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"151\">$SERVER{'article_name_label'}</td><td align=\"left\">$SERVER{'fabricant'}</a></td><td align=\"left\">$SERVER{'article_price_label'}</td></tr>";
    
    my $sort = $query->param("sort");
    my $add2;
    if ($sort) {
	$add2 = " ORDER BY $sort"  ;
    }
    
    
    my  ($c)= $db->sqlSelectMany($select, $from, "article.nom like '%$article%'  $add $add2 LIMIT $index_start, $index_end");

    while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'author'},$ARTICLE{'price'},$ARTICLE{'categorie_libelle_langue_ref_categorie'},$ARTICLE{'image'})=$c->fetchrow()) {
	if ($ARTICLE{'image'} eq '') {
	#    ##$ARTICLE{'image'} = "../images/blank.gif";
	}
        if ($ARTICLE{'categorie_libelle_langue_ref_categorie'} ne ''){
            $ARTICLE{'libelle'} = $db->sqlSelect ("libelle.libelle","categorie_libelle_langue, libelle, langue","categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' AND categorie_libelle_langue.ref_categorie = '$ARTICLE{'categorie_libelle_langue_ref_categorie'}'");
        }
        
	$string .= "<tr><td align=\"left\"><img alt=\"\" src=\"$ARTICLE{'image'}\"></td><td align=\"left\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'author'}</td><td align=\"left\">$ARTICLE{'price'}</td></tr>";
    }
    $string .="</table>";    
    return $string;
}


sub searchWatch {    
    my  $category = $query->param ('category');
    #$category  =~ s/[^\w ]//g;
    my  $subcategorie = $query->param('subcat');
    #$subcategorie  =~ s/[^\w ]//g;
    my $fabricant = $query->param ('fabricant') ;
    #$fabricant  =~ s/[^\w ]//g;
    my $valeur = $query->param ('valeur') ;
    #$valeur  =~ s/[^\w ]//g;    
    my $content;
    $session = new CGI::Session("driver:File", $session_id, {Directory=>"$session_dir"});
    my $level = $session->param("level");
	if ($level eq '2') {
	    $LINK{'admin'} = "<a href=\"javascript:void(0)\" class=\"menulink\"  onclick=\"window.open('/cgi-bin/recordz.cgi?lang=$lang&amp;page=cms_manage_article&amp;session=$session_id;','MyWindow','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=no,width=800,height=600,left=20,top=20')\">Admin</a>";
	}
	else {
	    $LINK{'admin'} = "";
	}
    
    
    my  $string = doSearchWatch ($category, $subcategorie, $fabricant, $valeur);
    my $categories = $lp->loadCategories();
    my  $string2 = doSearchWatchIndexed ($category, $subcategorie, $fabricant, $valeur);
    #my  $string3 = getSearchDepot();
    #my $subcategories = loadSearchWarchSubCategory ();
    #my $string4 = weekNews ();
    open (FILE, "<$dir/dosearchwatch.html") or die "cannot open file $dir/dosearchwatch.html";
    my $menu = loadMenu();
    #my $cats = getCat();
    
    my $subcat = "";
    while (<FILE>) {	
	s/\$LABEL{'([\w]+)'}/ exists $SERVER{$1} ? $SERVER{$1} : $1 /eg; 
	s/\$LANG/$lang/g;
	s/\$ERROR{'([\w]+)'}//g;
	s/\$ARTICLE{'index_table'}/$string/g;
	#s/\$ARTICLE{'news'}//g;
	s/\$OPTIONS{'categories'}/$categories/g;
	
	s/\$LINK{'admin'}/$LINK{'admin'}/g;
	s/\$SESSIONID/$session_id/g;
	s/\$ARTICLE{'main_menu'}/$menu/g;
	s/\$ARTICLE{'search'}/$string2/g;
	$content .= $_;	
    }
	$content = Compress::Zlib::memGzip($content)  if $can_do_gzip; ;
	print "Content-Length: ", length($content) , "\n";
	print "Content-Encoding: gzip\n" ;
	print "Content-Type: text/html\n\n"; 
	print $content;
        close (FILE);		
}

sub searchCd {
    my  $category = $query->param ('category');
    #$category  =~ s/[^\w ]//g;
    my  $subcategory = $query->param('subcat');
    #$subcategory  =~ s/[^\w ]//g;
    my $fabricant = $query->param ('fabricant');
    #$fabricant  =~ s/[^\w ]//g;#
    my $valeur = $query->param ('valeur');
    #$valeur  =~ s/[^\w ]//g;
    my $content;
    $session = new CGI::Session("driver:File", $session_id, {Directory=>"$session_dir"});
    my $level = $session->param("level");
	if ($level eq '2') {
	    $LINK{'admin'} = "<a href=\"javascript:void(0)\" class=\"menulink\"  onclick=\"window.open('/cgi-bin/recordz.cgi?lang=$lang&amp;page=cms_manage_article&amp;session=$session_id;','MyWindow','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=no,width=800,height=600,left=20,top=20')\">Admin</a>";
	}
	else {
	    $LINK{'admin'} = "";
	}
    
    
    my  $string =  doSearchCd ($category, $subcategory,$fabricant,$valeur);
    my  $string2 = doSearchCdIndexed ($category,$subcategory,$fabricant, $valeur);
    my $categories = $lp->loadCategories();
    open (FILE, "<$dir/dosearchbaby.html") or die "cannot open file $dir/dosearchbaby.html";
    my $menu = loadMenu();
  #  my $cats = getCat();
    while (<FILE>) {	
	s/\$LABEL{'([\w]+)'}/ exists $SERVER{$1} ? $SERVER{$1} : $1 /eg; 
	s/\$LANG/$lang/g;
	s/\$ERROR{'([\w]+)'}//g;
	s/\$ARTICLE{'index_table'}/$string/g;
	#s/\$SELECT{'depot'}/$string3/g;
	#s/\$ARTICLE{'news'}//g;
	s/\$OPTIONS{'categories'}/$categories/g;
	s/\$LINK{'admin'}/$LINK{'admin'}/g;
	s/\$SESSIONID/$session_id/g;
	s/\$ARTICLE{'main_menu'}/$menu/g;
	s/\$ARTICLE{'search'}/$string2/g;
	s/\$ARTICLE{'valeur'}/$valeur/g;
	$content .= $_;	
    }
	$content = Compress::Zlib::memGzip($content)  if $can_do_gzip; ;
	print "Content-Length: ", length($content) , "\n";
	print "Content-Encoding: gzip\n" ;
	print "Content-Type: text/html\n\n"; 
	print $content;
        close (FILE);
    
}

sub doSearchCd {
    my $category = $query->param("category");
    
    my $subcategory = $query->param("subcategory");
    
    my $fabricant = $query->param("fabricant");
    
    my $valeur = $query->param("valeur");
    #$valeur =~ s/[^\w ]//g;
    my $buy_price_min = $query->param ("price_min");
    #$buy_price_min =~ s/[^\w ]//g;    
    my $buy_price_max = $query->param("price_max");
    #$buy_price_max =~ s/[^\w ]//g;
    my $production_house = $query->param("production_house");
    my $used = $query->param("used");
    my $string;    
    my $select = "DISTINCT article.nom";        
    my  $from = "article, libelle, langue";
    my  $where = " id_article = id_article ";
    my $ref_cat;
    my $ref_subcat;
    my $add;
    if ($category) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $where .= " AND article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
	    $from .= ", categorie_libelle_langue ";
    }
    if ($subcategory) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcategory' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $where .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
    if ($production_house) {
        if ($production_house ne '--------') {
	    $where .= " AND marque = '$production_house'";
	}
	
    }    
    if ($fabricant) {if ($fabricant ne '---------') {$where .= " AND article.marque = '$fabricant'";}}
    if ($buy_price_min) {$where .= " AND article.prix >= '$buy_price_min'";}
    if ($buy_price_max) {$where .= " AND article.prix <= '$buy_price_max'";}
    if ($valeur) {$where .= " AND article.nom LIKE '%$valeur%'";}
      if ($used) {
	$from .= ",etat_libelle_langue";
	if ($where ne ''){
		$where .= " AND article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}else {
		$where .= " article.ref_etat = id_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}
    }

    my  $total = '0';    
    my  ($d)= $db->sqlSelect("count(id_article)", $from, $where ." AND ref_statut = '3'");
    
    my  $nb_page = arrondi ($d / 40, 1);my  $min_index = '0';my  $max_index = '40';

    for (my  $i = '0'; $i < $nb_page;$i++) {
	my $n2 = $i %= 10;
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=dosearchwear&amp;min_index=$min_index&amp;session=$session_id&category=$category&fabricant=$fabricant&price_min=$buy_price_min&price_max=$buy_price_max&subcategory=$subcategory\"  class=\"menulink2\" ><-$i-></a>&#160;&nbsp;<img alt=\"\" alt=\"\" src=\"../images/next2.gif\" height=\"13px\" width=\"13px\">";		
	$min_index += 40;	
    }
    return $string;
}

sub doSearchBoat {
    my $category = $query->param("category");
    my $longueur = $query->param("longueur");
    my $largeur = $query->param("largeur");
    my $buy_price_min = $query->param ("price_min");
    #$buy_price_min =~ s/[^\w ]//g;    
    my $buy_price_max = $query->param("price_max");
    #$buy_price_max =~ s/[^\w ]//g;
    my $used = $query->param("used");
    my $string;    
    my $select = "DISTINCT article.nom";        
    my  $from = "article";
    my  $where = " id_article = id_article ";
    my $ref_cat;
    my $ref_subcat;
    my $add;
    if ($category) {
            my  @sub_cat = $db->sqlSelect1("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $where .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
    
    if ($buy_price_min) {$where .= " AND article.prix >= '$buy_price_min'";}
    if ($buy_price_max) {$where .= " AND article.prix <= '$buy_price_max'";}
    if ($longueur) {$where .= " AND article.longueur = '$longueur'";	}
    if ($largeur) {$where .= " AND article.largeur = '$largeur'";}
      if ($used) {
	$from .= ",etat_libelle_langue";
	if ($where ne ''){
		$where .= " AND article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}else {
		$where .= " article.ref_etat = id_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}
    }

    my  $total = '0';    
    my  ($d)= $db->sqlSelect("count(id_article)", $from, $where ." AND ref_statut = '3' and article.ref_categorie = 94");
    
    my  $nb_page = arrondi ($d / 40, 1);my  $min_index = '0';my  $max_index = '40';

    for (my  $i = '0'; $i < $nb_page;$i++) {
	my $n2 = $i %= 10;
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=dosearchwear&amp;min_index=$min_index&category=$category&price_min=$buy_price_min&price_max=$buy_price_max&category=$category\"  class=\"menulink2\" ><-$i-></a>&#160;&nbsp;<img alt=\"\" alt=\"\" src=\"../images/next2.gif\" height=\"13px\" width=\"13px\">";		
	$min_index += 40;	
    }
    return $string;
}

sub doSearchBoatIndexed {
    my $category = $query->param("category");
    my $buy_price_min = $query->param ("longueur");
    my $buy_price_max = $query->param("largeur");
    my $longueur = $query->param("longueur");
    my $largeur = $query->param("largeur");
    my $used = $query->param("used");
    my $string;    
    my $select = "DISTINCT article.nom,id_article, prix,pochette,marque";
    my  $from = "article, libelle, langue";
    my  $where = "id_article = id_article ";
    my $ref_cat;
    my $ref_subcat;
    my $add;
    if ($category) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $where .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
    if ($buy_price_min) {$where .= " AND article.prix >= '$buy_price_min'";	}
    if ($buy_price_max) {$where .= " AND article.prix <= '$buy_price_max'";	}
    if ($longueur) {$where .= " AND article.longueur = '$longueur'";	}
    if ($largeur) {$where .= " AND article.largeur = '$largeur'";}
         if ($used) {
	$from .= ",etat_libelle_langue";
	if ($where ne ''){
		$where .= " AND article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}else {
		$where .= " article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}
    }
    my  $total = '0';  
    my  ($d)= $db->sqlSelectMany($select, $from, $where ." AND ref_statut = '3' and article.ref_categorie = 94");
    my  $index_start = $query->param ("min_index") ;$index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index") ; $index_end=~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d",$year+1900,$mon+1,$mday;    
    if (!$index_start ) {$index_start = 0;}if (!$index_end ) {$index_end = 40;}
    $string = "<table style=\"border-width:thin; border-style:dotted; border-top-color:#94CEFA;border-right-color:#94CEFA;border-left-color:#94CEFA; border-right-width:2px; border-bottom-color:#94CEFA\" width=\"555\" border=\"0\"><tr bgcolor=\"#DBE4F8\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"120\">$SERVER{'article_name_label'}</td><td align=\"left\" width=\"120\">$SERVER{'fabricant'}</td><td align=\"left\">$SERVER{'article_price_label'}</td><td align=\"left\"></td></tr>";
    my  ($c)= $db->sqlSelectMany($select, $from, $where ." and article.ref_categorie = 94 LIMIT $index_start, $index_end");
    while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'price'},$ARTICLE{'image'},$ARTICLE{'fabricant'})=$c->fetchrow()) {
	$string .= "<tr><td align=\"left\"><img alt=\"\" alt=\"\" src=\"$ARTICLE{'image'}\"></td><td align=\"left\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'fabricant'}</td><td align=\"left\">$ARTICLE{'price'}</td><td align=\"left\">$ARTICLE{'depot'}</td></tr>";
    }
    $string .="</table>";    
    return $string;
}


#load search index result
sub doSearchCdIndexed {
    my $category = $query->param("category");
    my $subcategory = $query->param("subcategory");
    my $fabricant = $query->param("fabricant");
    my $valeur = $query->param("valeur");
    my $buy_price_min = $query->param ("price_min");
    my $buy_price_max = $query->param("price_max");
    my $taille = $query->param("taille");
    
    my $used = $query->param("used");
    my $string;    
    my $select = "DISTINCT article.nom,id_article, prix,pochette,marque";
    my  $from = "article, libelle, langue";
    my  $where = "id_article = id_article ";
    my $ref_cat;
    my $ref_subcat;
    my $add;
    if ($category) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $where .= " AND article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
	    $from .= ", categorie_libelle_langue ";
    }
    if ($subcategory) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcategory' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $where .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
    
    if ($taille) {$where .= " AND article.taille = '$taille'";}
    
    if ($valeur) {$where .= " AND article.nom LIKE '%$valeur%'";}    
    
    if ($fabricant) {if ($fabricant ne '---------') {$where .= " AND article.marque = '$fabricant'";}}
    if ($buy_price_min) {$where .= " AND article.prix >= '$buy_price_min'";	}
    if ($buy_price_max) {$where .= " AND article.prix <= '$buy_price_max'";	}
    if ($valeur) {$where .= " AND article.nom LIKE '%$valeur%'";}
         if ($used) {
	$from .= ",etat_libelle_langue";
	if ($where ne ''){
		$where .= " AND article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}else {
		$where .= " article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}
    }
    my  $total = '0';  
    my  ($d)= $db->sqlSelectMany($select, $from, $where ." AND ref_statut = '3'");
    my  $index_start = $query->param ("min_index") ;$index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index") ; $index_end=~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d",$year+1900,$mon+1,$mday;    
    if (!$index_start ) {$index_start = 0;}if (!$index_end ) {$index_end = 40;}
    $string = "<table style=\"border-width:thin; border-style:dotted; border-top-color:#94CEFA;border-right-color:#94CEFA;border-left-color:#94CEFA; border-right-width:2px; border-bottom-color:#94CEFA\" width=\"555\" border=\"0\"><tr bgcolor=\"#DBE4F8\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"120\">$SERVER{'article_name_label'}</td><td align=\"left\" width=\"120\">$SERVER{'fabricant'}</td><td align=\"left\">$SERVER{'article_price_label'}</td><td align=\"left\"></td></tr>";
    my  ($c)= $db->sqlSelectMany($select, $from, $where ." LIMIT $index_start, $index_end");
    while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'price'},$ARTICLE{'image'},$ARTICLE{'fabricant'})=$c->fetchrow()) {
	$string .= "<tr><td align=\"left\"><img alt=\"\" alt=\"\" src=\"$ARTICLE{'image'}\"></td><td align=\"left\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'fabricant'}</td><td align=\"left\">$ARTICLE{'price'}</td><td align=\"left\">$ARTICLE{'depot'}</td></tr>";
    }
    $string .="</table>";    
    return $string;
}
sub searchBaby {
     my  $category = $query->param ('category');
    #$category  =~ s/[^\w ]//g;
    my  $subcategory = $query->param('subcategory');
    #$subcategory  =~ s/[^\w ]//g;or
    my $fabricant = $query->param ('fabricant');
    #$fabricant  =~ s/[^\w ]//g;
    my $valeur = $query->param ('valeur');
    #$valeur  =~ s/[^\w ]//g;
    my $content;
    $session = new CGI::Session("driver:File", $session_id, {Directory=>"$session_dir"});
    my $level = $session->param("level");
	if ($level eq '2') {
	    $LINK{'admin'} = "<a href=\"javascript:void(0)\" class=\"menulink\"  onclick=\"window.open('/cgi-bin/recordz.cgi?lang=$lang&amp;page=cms_manage_article&amp;session=$session_id;','MyWindow','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=no,width=800,height=600,left=20,top=20')\">Admin</a>";
	}
	else {
	    $LINK{'admin'} = "";
	}
    
    
    my  $string = doSearchBaby ($category, $subcategory,$fabricant,$valeur);
    my  $string2 = doSearchBabyIndexed ($category,$subcategory,$fabricant, $valeur);
    
    open (FILE, "<$dir/dosearchbaby.html") or die "cannot open file $dir/dosearchbaby.html";
    my $menu = loadMenu();
    my $categories = $lp->loadCategories();
  #  my $cats = getCat();
    while (<FILE>) {	
	s/\$LABEL{'([\w]+)'}/ exists $SERVER{$1} ? $SERVER{$1} : $1 /eg; 
	s/\$LANG/$lang/g;
	s/\$ERROR{'([\w]+)'}//g;
	s/\$ARTICLE{'index_table'}/$string/g;
	#s/\$SELECT{'depot'}/$string3/g;
	#s/\$ARTICLE{'news'}//g;
	s/\$OPTIONS{'categories'}/$categories/g;
	s/\$LINK{'admin'}/$LINK{'admin'}/g;
	s/\$SESSIONID/$session_id/g;
	s/\$ARTICLE{'main_menu'}/$menu/g;
	s/\$ARTICLE{'search'}/$string2/g;
	s/\$ARTICLE{'valeur'}/$valeur/g;
	$content .= $_;	
    }
	$content = Compress::Zlib::memGzip($content)  if $can_do_gzip; ;
	print "Content-Length: ", length($content) , "\n";
	print "Content-Encoding: gzip\n" ;
	print "Content-Type: text/html\n\n"; 
	print $content;
        close (FILE);
}

sub searchAstro {
    my  $category = $query->param ('category');
    #$category  =~ s/[^\w ]//g;
    my  $subcategory = $query->param('subcat');
    #$subcategory  =~ s/[^\w ]//g;
    my $fabricant = $query->param ('fabricant');
    #$fabricant  =~ s/[^\w ]//g;
    my $valeur = $query->param ('valeur');
    #$valeur  =~ s/[^\w ]//g;
    my $content;
    $session = new CGI::Session("driver:File", $session_id, {Directory=>"$session_dir"});
    my $level = $session->param("level");
	if ($level eq '2') {
	    $LINK{'admin'} = "<a href=\"javascript:void(0)\" class=\"menulink\"  onclick=\"window.open('/cgi-bin/recordz.cgi?lang=$lang&amp;page=cms_manage_article&amp;session=$session_id;','MyWindow','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=no,width=800,height=600,left=20,top=20')\">Admin</a>";
	}
	else {
	    $LINK{'admin'} = "";
	}
    
    
    my  $string =  doSearchAstro ($category, $subcategory,$fabricant,$valeur);
    my  $string2 = doSearchAstroIndexed ($category,$subcategory,$fabricant, $valeur);;
    #my  $string3 = getSearchDepot();
    $valeur = loadSearchParfumValeur ();
    my $categories = $lp->loadCategories();
    open (FILE, "<$dir/dosearchastro.html") or die "cannot open file $dir/dosearchastro.html";
    my $menu = loadMenu();
  #  my $cats = getCat();
    while (<FILE>) {	
	s/\$LABEL{'([\w]+)'}/ exists $SERVER{$1} ? $SERVER{$1} : $1 /eg; 
	s/\$LANG/$lang/g;
	s/\$ERROR{'([\w]+)'}//g;
	s/\$ARTICLE{'index_table'}/$string/g;
	#s/\$SELECT{'depot'}/$string3/g;
	#s/\$ARTICLE{'news'}//g;
	s/\$OPTIONS{'categories'}/$categories/g;
	s/\$LINK{'admin'}/$LINK{'admin'}/g;
	s/\$SESSIONID/$session_id/g;
	s/\$ARTICLE{'main_menu'}/$menu/g;
	s/\$ARTICLE{'search'}/$string2/g;
	s/\$ARTICLE{'valeur'}/$valeur/g;
	$content .= $_;	
    }
	$content = Compress::Zlib::memGzip($content)  if $can_do_gzip; ;
	print "Content-Length: ", length($content) , "\n";
	print "Content-Encoding: gzip\n" ;
	print "Content-Type: text/html\n\n"; 
	print $content;
        close (FILE);
}



sub searchParfum {
    my  $category = $query->param ('category');
    #$category  =~ s/[^\w ]//g;
    my  $subcategory = $query->param('subcat');
    #$subcategory  =~ s/[^\w ]//g;
    my $fabricant = $query->param ('fabricant');
    #$fabricant  =~ s/[^\w ]//g;
    my $valeur = $query->param ('valeur');
    #$valeur  =~ s/[^\w ]//g;
    my $content;
    $session = new CGI::Session("driver:File", $session_id, {Directory=>"$session_dir"});
    my $level = $session->param("level");
	if ($level eq '2') {
	    $LINK{'admin'} = "<a href=\"javascript:void(0)\" class=\"menulink\"  onclick=\"window.open('/cgi-bin/recordz.cgi?lang=$lang&amp;page=cms_manage_article&amp;session=$session_id;','MyWindow','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=no,width=800,height=600,left=20,top=20')\">Admin</a>";
	}
	else {
	    $LINK{'admin'} = "";
	}
    
    
    my  $string =  doSearchParfum ($category, $subcategory,$fabricant,$valeur);
    my  $string2 = doSearchParfumIndexed ($category,$subcategory,$fabricant, $valeur);;
    #my  $string3 = getSearchDepot();
    $valeur = loadSearchParfumValeur ();
    my $categories = $lp->loadCategories();
    open (FILE, "<$dir/dosearchparfum.html") or die "cannot open file $dir/dosearchparfum.html";
    my $menu = loadMenu();
  #  my $cats = getCat();
    while (<FILE>) {	
	s/\$LABEL{'([\w]+)'}/ exists $SERVER{$1} ? $SERVER{$1} : $1 /eg; 
	s/\$LANG/$lang/g;
	s/\$ERROR{'([\w]+)'}//g;
	s/\$ARTICLE{'index_table'}/$string/g;
	#s/\$SELECT{'depot'}/$string3/g;
	#s/\$ARTICLE{'news'}//g;
	s/\$OPTIONS{'categories'}/$categories/g;
	s/\$LINK{'admin'}/$LINK{'admin'}/g;
	s/\$SESSIONID/$session_id/g;
	s/\$ARTICLE{'main_menu'}/$menu/g;
	s/\$ARTICLE{'search'}/$string2/g;
	s/\$ARTICLE{'valeur'}/$valeur/g;
	$content .= $_;	
    }
	$content = Compress::Zlib::memGzip($content)  if $can_do_gzip; ;
	print "Content-Length: ", length($content) , "\n";
	print "Content-Encoding: gzip\n" ;
	print "Content-Type: text/html\n\n"; 
	print $content;
        close (FILE);		
}
    
sub doSearchParfum {
    my $category = $query->param("category");
    #$category  =~ s/[^\w ]//g;    
    my $subcategory = $query->param("subcategory");
    
    my $fabricant = $query->param("fabricant");
    #$fabricant =~ s/[^\w ]//g;    
    my $valeur = $query->param("valeur");
    #$valeur =~ s/[^\w ]//g;
    my $buy_price_min = $query->param ("price_min");
    #$buy_price_min =~ s/[^\w ]//g;    
    my $buy_price_max = $query->param("price_max");
    #$buy_price_max =~ s/[^\w ]//g;
    my $used = $query->param("used");
    my $string;    
    my $select = "DISTINCT article.nom";        
    my  $from = "article, libelle, langue";
    my  $where = " id_article = id_article ";
    my $ref_cat;
    my $ref_subcat;
    my $add;
    if ($category) {
    	    $ref_cat = 0;
	    $where .= " AND article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
	    $from .= ", categorie_libelle_langue ";
    }
    if ($subcategory) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcategory' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $where .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
    if ($fabricant) {if ($fabricant ne '---------') {$where .= " AND article.marque = '$fabricant'";}}
    if ($buy_price_min) {$where .= " AND article.prix >= '$buy_price_min'";}
    if ($buy_price_max) {$where .= " AND article.prix <= '$buy_price_max'";}
    if ($valeur) {$where .= " AND article.nom LIKE '%$valeur%'";}
      if ($used) {
	$from .= ",etat_libelle_langue";
	if ($where ne ''){
		$where .= " AND article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}else {
		$where .= " article.ref_etat = id_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}
    }

    my  $total = '0';    
    my  ($d)= $db->sqlSelect("count(id_article)", $from, $where ." AND ref_statut = '3'");
    
    my  $nb_page = arrondi ($d / 40, 1);my  $min_index = '0';my  $max_index = '40';

    for (my  $i = '0'; $i < $nb_page;$i++) {
	my $n2 = $i %= 10;
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=dosearchwear&amp;min_index=$min_index&amp;session=$session_id&category=$category&fabricant=$fabricant&price_min=$buy_price_min&price_max=$buy_price_max&subcategory=$subcategory\"  class=\"menulink2\" ><-$i-></a>&#160;&nbsp;<img alt=\"\" alt=\"\" src=\"../images/next2.gif\" height=\"13px\" width=\"13px\">";		
	$min_index += 40;	
    }
    return $string;
}
#load search index result
sub doSearchParfumIndexed {    
    my $category = $query->param("category");
    #$category  =~ s/[^\w ]//g;    
    my $subcategory = $query->param("subcategory");
    #$subcategory  =~ s/[^\w ]//g;    
    my $fabricant = $query->param("fabricant");
    #$fabricant =~ s/[^\w ]//g;    
    my $valeur = $query->param("valeur");
    #$valeur =~ s/[^\w ]//g;
    my $buy_price_min = $query->param ("price_min");
    #$buy_price_min =~ s/[^\w ]//g;    
    my $buy_price_max = $query->param("price_max");
    #$buy_price_max =~ s/[^\w ]//g;
    my $taille = $query->param("taille");
    my $used = $query->param("used");
    my $string;    
    my $select = "DISTINCT article.nom,id_article, prix,pochette,marque";
    my  $from = "article, libelle, langue";
    my  $where = "id_article = id_article ";
    my $ref_cat;
    my $ref_subcat;
    my $add;
    if ($category) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $where .= " AND article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
	    $from .= ", categorie_libelle_langue ";
    }
    if ($subcategory) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcategory' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $where .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
    
    if ($taille) {$where .= " AND article.taille = '$taille'";}
    
    if ($valeur) {$where .= " AND article.nom LIKE '%$valeur%'";}    
    
    if ($fabricant) {if ($fabricant ne '---------') {$where .= " AND article.marque = '$fabricant'";}}
    if ($buy_price_min) {$where .= " AND article.prix >= '$buy_price_min'";	}
    if ($buy_price_max) {$where .= " AND article.prix <= '$buy_price_max'";	}
    if ($valeur) {$where .= " AND article.nom LIKE '%$valeur%'";}
         if ($used) {
	$from .= ",etat_libelle_langue";
	if ($where ne ''){
		$where .= " AND article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}else {
		$where .= " article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}
    }
    my  $total = '0';  
    my  ($d)= $db->sqlSelectMany($select, $from, $where ." AND ref_statut = '3'");
    my  $index_start = $query->param ("min_index") ;$index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index") ; $index_end=~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d",$year+1900,$mon+1,$mday;    
    if (!$index_start ) {$index_start = 0;}if (!$index_end ) {$index_end = 40;}
    $string = "<table style=\"border-width:thin; border-style:dotted; border-top-color:#94CEFA;border-right-color:#94CEFA;border-left-color:#94CEFA; border-right-width:2px; border-bottom-color:#94CEFA\" width=\"555\" border=\"0\"><tr bgcolor=\"#DBE4F8\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"120\">$SERVER{'article_name_label'}</td><td align=\"left\" width=\"120\">$SERVER{'fabricant'}</td><td align=\"left\">$SERVER{'article_price_label'}</td><td align=\"left\"></td></tr>";
    my  ($c)= $db->sqlSelectMany($select, $from, $where ." LIMIT $index_start, $index_end");
    while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'price'},$ARTICLE{'image'},$ARTICLE{'fabricant'})=$c->fetchrow()) {
	$string .= "<tr><td align=\"left\"><img alt=\"\" alt=\"\" src=\"$ARTICLE{'image'}\"></td><td align=\"left\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'fabricant'}</td><td align=\"left\">$ARTICLE{'price'}</td><td align=\"left\">$ARTICLE{'depot'}</td></tr>";
    }
    $string .="</table>";    
    return $string;
}
    
sub doSearchBaby {
    my $category = $query->param("category");
    #$category  =~ s/[^\w ]//g;    
    my $subcategory = $query->param("subcategory");
    
    my $fabricant = $query->param("fabricant");
    #$fabricant =~ s/[^\w ]//g;    
    my $valeur = $query->param("valeur");
    #$valeur =~ s/[^\w ]//g;
    my $buy_price_min = $query->param ("price_min");
    #$buy_price_min =~ s/[^\w ]//g;    
    my $buy_price_max = $query->param("price_max");
    #$buy_price_max =~ s/[^\w ]//g;
    my $used = $query->param("used");
    my $string;    
    my $select = "DISTINCT article.nom";        
    my  $from = "article";
    my  $where = " id_article = id_article ";
    my $ref_cat;
    my $ref_subcat;
    my $add;
    if ($category) {
    	    $ref_cat = 0;
	    $where .= " AND article.ref_categorie = 23";
	    $from .= " ";
    }
    if ($subcategory) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcategory' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $where .= " AND article.ref_subcategorie = $ref_subcat";
	    $from .= " ";
    }
    if ($fabricant) {if ($fabricant ne '---------') {$where .= " AND article.marque = '$fabricant'";}}
    if ($buy_price_min) {$where .= " AND article.prix >= '$buy_price_min'";}
    if ($buy_price_max) {$where .= " AND article.prix <= '$buy_price_max'";}
    if ($valeur) {$where .= " AND article.nom LIKE '%$valeur%'";}
      if ($used) {
	$from .= ",etat_libelle_langue";
	if ($where ne ''){
		$where .= " AND article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}else {
		$where .= " article.ref_etat = id_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}
    }

    my  $total = '0';    
    my  ($d)= $db->sqlSelect("count(id_article)", $from, $where ." AND ref_statut = '3'");
    
    my  $nb_page = arrondi ($d / 40, 1);my  $min_index = '0';my  $max_index = '40';

    for (my  $i = '0'; $i < $nb_page;$i++) {
	my $n2 = $i %= 10;
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=dosearchwear&amp;min_index=$min_index&amp;session=$session_id&category=$category&fabricant=$fabricant&price_min=$buy_price_min&price_max=$buy_price_max&subcategory=$subcategory\"  class=\"menulink2\" ><-$i-></a>&#160;&nbsp;<img alt=\"\" alt=\"\" src=\"../images/next2.gif\" height=\"13px\" width=\"13px\">";		
	$min_index += 40;	
    }
    
    return $string;
}
#load search index result
sub doSearchBabyIndexed {    
    my $category = $query->param("category");
    #$category  =~ s/[^\w ]//g;    
    my $subcategory = $query->param("subcategory");
        #$subcategory  =~ s/[^\w ]//g;    
    my $fabricant = $query->param("fabricant");
    #$fabricant =~ s/[^\w ]//g;    
    my $valeur = $query->param("valeur");
    #$valeur =~ s/[^\w ]//g;
    my $buy_price_min = $query->param ("price_min");
    #$buy_price_min =~ s/[^\w ]//g;    
    my $buy_price_max = $query->param("price_max");
    #$buy_price_max =~ s/[^\w ]//g;
    my $taille = $query->param("taille");
    my $used = $query->param("used");
    my $string;    
    my $select = "DISTINCT article.nom,id_article, prix,pochette,marque";
    my  $from = "article, libelle, langue";
    my  $where = "id_article = id_article ";
    my $ref_cat;
    my $ref_subcat;
    my $add;
    if ($category) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $where .= " AND article.ref_categorie = 23 AND categorie_libelle_langue.ref_categorie = 23 and  article.ref_categorie = 23";
	    $from .= ", categorie_libelle_langue ";
    }
    if ($subcategory) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcategory' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $where .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
    
    if ($taille) {$where .= " AND article.taille = '$taille'";}
    
    if ($valeur) {$where .= " AND article.nom LIKE '%$valeur%'";}    
    
    if ($fabricant) {if ($fabricant ne '---------') {$where .= " AND article.marque = '$fabricant'";}}
    if ($buy_price_min) {$where .= " AND article.prix >= '$buy_price_min'";	}
    if ($buy_price_max) {$where .= " AND article.prix <= '$buy_price_max'";	}
    if ($valeur) {$where .= " AND article.nom LIKE '%$valeur%'";}
         if ($used) {
	$from .= ",etat_libelle_langue";
	if ($where ne ''){
		$where .= " AND article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}else {
		$where .= " article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}
    }
    my  $total = '0';  
    
    my  $index_start = $query->param ("min_index") ;$index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index") ; $index_end=~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d",$year+1900,$mon+1,$mday;    
    if (!$index_start ) {$index_start = 0;}if (!$index_end ) {$index_end = 40;}
    $string = "<table style=\"border-width:thin; border-style:dotted; border-top-color:#94CEFA;border-right-color:#94CEFA;border-left-color:#94CEFA; border-right-width:2px; border-bottom-color:#94CEFA\" width=\"555\" border=\"0\"><tr bgcolor=\"#DBE4F8\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"120\">$SERVER{'article_name_label'}</td><td align=\"left\" width=\"120\">$SERVER{'fabricant'}</td><td align=\"left\">$SERVER{'article_price_label'}</td><td align=\"left\"></td></tr>";
    my  ($c)= $db->sqlSelectMany($select, $from, $where ." LIMIT $index_start, $index_end");
    while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'price'},$ARTICLE{'image'},$ARTICLE{'fabricant'})=$c->fetchrow()) {
	$string .= "<tr><td align=\"left\"><img alt=\"\" alt=\"\" src=\"$ARTICLE{'image'}\"></td><td align=\"left\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'fabricant'}</td><td align=\"left\">$ARTICLE{'price'}</td><td align=\"left\">$ARTICLE{'depot'}</td></tr>";
    }
    $string .="</table>";    
    return $string;
}

sub searchArt {
    my $category = $query->param('category');
    #$category  =~ s/[^\w ]//g;    
    my $subcategory = $query->param('subcategory');
   # $category  =~ s/[^\w ]//g;    
    my $fabricant = $query->param('fabricant');
   # $fabricant =~ s/[^\w ]//g;    
    my $valeur = $query->param('valeur');
   # $valeur  =~ s/[^\w ]//g;    
    my $buy_price_min = $query->param ('price_min');
   # $buy_price_min  =~ s/[^\w ]//g;
    my $buy_price_max = $query->param('price_max');
   # $buy_price_max  =~ s/[^\w ]//g;
    my $content;
    $session = new CGI::Session("driver:File", $session_id, {Directory=>"$session_dir"});
    my $level = $session->param("level");
	if ($level eq '2') {
	    $LINK{'admin'} = "<a href=\"javascript:void(0)\" class=\"menulink\"  onclick=\"window.open('/cgi-bin/recordz.cgi?lang=$lang&amp;page=cms_manage_article&amp;session=$session_id;','MyWindow','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=no,width=800,height=600,left=20,top=20')\">Admin</a>";
	}
	else {
	    $LINK{'admin'} = "";
	}
    
    
    my  $string =  doSearchArt ($category, $subcategory,$fabricant, $valeur);
    my  $string2 = doSearchArtIndexed ($category, $subcategory,$fabricant, $valeur);
    
    
    open (FILE, "<$dir/dosearchart.html") or die "cannot open file $dir/dosearchart.html";
    my $menu = loadMenu();
    my $categories = $lp->loadCategories();
    while (<FILE>) {	
	s/\$LABEL{'([\w]+)'}/ exists $SERVER{$1} ? $SERVER{$1} : $1 /eg; 
	s/\$LANG/$lang/g;
	s/\$ERROR{'([\w]+)'}//g;
	s/\$ARTICLE{'index_table'}/$string/g;
	s/\$LINK{'admin'}/$LINK{'admin'}/g;
	s/\$SESSIONID/$session_id/g;
	s/\$ARTICLE{'main_menu'}/$menu/g;
	s/\$ARTICLE{'search'}/$string2/g;
	s/\$OPTIONS{'categories'}/$categories/g;
	$content .= $_;	
    }
	$content = Compress::Zlib::memGzip($content)  if $can_do_gzip; ;
	print "Content-Length: ", length($content) , "\n";
	print "Content-Encoding: gzip\n" ;
	print "Content-Type: text/html\n\n"; 
	print $content;
        close (FILE);		
}

sub searchJardin {
    my $category = $query->param('category');
   # $category  =~ s/[^\w ]//g;    
    my $subcategory = $query->param('subcategory');
   # $category  =~ s/[^\w ]//g;    
    my $fabricant = $query->param('fabricant');
   # $fabricant =~ s/[^\w ]//g;    
    my $valeur = $query->param('valeur');
   # $valeur  =~ s/[^\w ]//g;    
    my $buy_price_min = $query->param ("price_min");
   #  $buy_price_min  =~ s/[^\w ]//g;
    my $buy_price_max = $query->param("price_max");
   #  $buy_price_max  =~ s/[^\w ]//g;
    my $content;
    $session = new CGI::Session("driver:File", $session_id, {Directory=>"$session_dir"});
    my $level = $session->param("level");
	if ($level eq '2') {
	    $LINK{'admin'} = "<a href=\"javascript:void(0)\" class=\"menulink\"  onclick=\"window.open('/cgi-bin/recordz.cgi?lang=$lang&amp;page=cms_manage_article&amp;session=$session_id;','MyWindow','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=no,width=800,height=600,left=20,top=20')\">Admin</a>";
	}
	else {
	    $LINK{'admin'} = "";
	}
    
    
    my  $string =  doSearchJardin ($category, $subcategory,$fabricant, $valeur);
    my  $string2 = doSearchJardinIndexed ($category, $subcategory,$fabricant, $valeur);
    my $categories = $lp->loadCategories();
    
    open (FILE, "<$dir/dosearchjardin.html") or die "cannot open file $dir/dosearchjardin.html";
    my $menu = loadMenu();
    #my $cats = getCat();
    while (<FILE>) {	
	s/\$LABEL{'([\w]+)'}/ exists $SERVER{$1} ? $SERVER{$1} : $1 /eg; 
	s/\$LANG/$lang/g;
	s/\$ERROR{'([\w]+)'}//g;
	s/\$ARTICLE{'index_table'}/$string/g;	
	#s/\$ARTICLE{'news'}//g;
	s/\$OPTIONS{'categories'}/$categories/g;
	s/\$LINK{'admin'}/$LINK{'admin'}/g;
	s/\$SESSIONID/$session_id/g;
	s/\$ARTICLE{'main_menu'}/$menu/g;
	s/\$ARTICLE{'search'}/$string2/g;
	$content .= $_;	
    }
	$content = Compress::Zlib::memGzip($content)  if $can_do_gzip; ;
	print "Content-Length: ", length($content) , "\n";
	print "Content-Encoding: gzip\n" ;
	print "Content-Type: text/html\n\n";
	#print "test";
	print $content;
        close (FILE);		
}

sub searchSport {
    my $category = $query->param('category');
   # $category  =~ s/[^\w ]//g;    
    my $subcategory = $query->param('subcategory');
   # $category  =~ s/[^\w ]//g;    
    my $fabricant = $query->param('fabricant');
   # $fabricant =~ s/[^\w ]//g;    
    my $valeur = $query->param('valeur');
   # $valeur  =~ s/[^\w ]//g;    
    my $buy_price_min = $query->param ("price_min");
   # $buy_price_min  =~ s/[^\w ]//g;
    my $buy_price_max = $query->param("price_max");
   # $buy_price_max  =~ s/[^\w ]//g;
    my $content;
    $session = new CGI::Session("driver:File", $session_id, {Directory=>"$session_dir"});
    my $level = $session->param("level");
	if ($level eq '2') {
	    $LINK{'admin'} = "<a href=\"javascript:void(0)\" class=\"menulink\"  onclick=\"window.open('/cgi-bin/recordz.cgi?lang=$lang&amp;page=cms_manage_article&amp;session=$session_id;','MyWindow','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=no,width=800,height=600,left=20,top=20')\">Admin</a>";
	}
	else {
	    $LINK{'admin'} = "";
	}
    
    
    my  $string =  doSearchSport ($category, $subcategory,$fabricant, $valeur);
    my  $string2 = doSearchSportIndexed ($category, $subcategory,$fabricant, $valeur);
    
    my $categories = $lp->loadCategories();
    open (FILE, "<$dir/dosearchjardin.html") or die "cannot open file $dir/dosearchjardin.html";
    my $menu = loadMenu();
    #my $cats = getCat();
    while (<FILE>) {	
	s/\$LABEL{'([\w]+)'}/ exists $SERVER{$1} ? $SERVER{$1} : $1 /eg; 
	s/\$LANG/$lang/g;
	s/\$ERROR{'([\w]+)'}//g;
	s/\$ARTICLE{'index_table'}/$string/g;	
	#s/\$ARTICLE{'news'}//g;
	s/\$OPTIONS{'categories'}/$categories/g;
	s/\$LINK{'admin'}/$LINK{'admin'}/g;
	s/\$SESSIONID/$session_id/g;
	s/\$ARTICLE{'main_menu'}/$menu/g;
	s/\$ARTICLE{'search'}/$string2/g;
	$content .= $_;	
    }
	$content = Compress::Zlib::memGzip($content)  if $can_do_gzip; ;
	print "Content-Length: ", length($content) , "\n";
	print "Content-Encoding: gzip\n" ;
	print "Content-Type: text/html\n\n"; 
	print $content;
        close (FILE);		
}

sub searchImmo {
    my $category = $query->param('category');
   # $category  =~ s/[^\w ]//g;    
    my $subcategory = $query->param('subcategory');
   # $category  =~ s/[^\w ]//g;    
    my $fabricant = $query->param('fabricant');
   # $fabricant =~ s/[^\w ]//g;    
    my $valeur = $query->param('valeur');
   # $valeur  =~ s/[^\w ]//g;    
    my $buy_price_min = $query->param ("price_min");
   #  $buy_price_min  =~ s/[^\w ]//g;
    my $buy_price_max = $query->param("price_max");
   #  $buy_price_max  =~ s/[^\w ]//g;
    my $content;
    $session = new CGI::Session("driver:File", $session_id, {Directory=>"$session_dir"});
    my $level = $session->param("level");
	if ($level eq '2') {
	    $LINK{'admin'} = "<a href=\"javascript:void(0)\" class=\"menulink\"  onclick=\"window.open('/cgi-bin/recordz.cgi?lang=$lang&amp;page=cms_manage_article&amp;session=$session_id;','MyWindow','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=no,width=800,height=600,left=20,top=20')\">Admin</a>";
	}
	else {
	    $LINK{'admin'} = "";
	}
    
    
    my  $string =  doSearchImmoIndex ($category, $subcategory,$fabricant, $valeur);
    my  $string2 = doSearchImmoIndexed ($category, $subcategory,$fabricant, $valeur);
    my $categories = $lp->loadCategories();
    
    open (FILE, "<$dir/dosearchjardin.html") or die "cannot open file $dir/dosearchjardin.html";
    my $menu = loadMenu();
    #my $cats = getCat();
    while (<FILE>) {	
	s/\$LABEL{'([\w]+)'}/ exists $SERVER{$1} ? $SERVER{$1} : $1 /eg; 
	s/\$LANG/$lang/g;
	s/\$ERROR{'([\w]+)'}//g;
	s/\$ARTICLE{'index_table'}/$string/g;	
	#s/\$ARTICLE{'news'}//g;
	s/\$OPTIONS{'categories'}/$categories/g;
	s/\$LINK{'admin'}/$LINK{'admin'}/g;
	s/\$SESSIONID/$session_id/g;
	s/\$ARTICLE{'main_menu'}/$menu/g;
	s/\$ARTICLE{'search'}/$string2/g;
	$content .= $_;	
    }
	$content = Compress::Zlib::memGzip($content)  if $can_do_gzip; ;
	print "Content-Length: ", length($content) , "\n";
	print "Content-Encoding: gzip\n" ;
	print "Content-Type: text/html\n\n"; 
	print $content;
        close (FILE);		
}

sub doSearchImmoIndex {
    my $category = $query->param("category");
   # $category  =~ s/[^\w ]//g;    
    my $subcategory = $query->param("subcategory");
    #$subcategory  =~ s/[^\w ]//g;    
    my $fabricant = $query->param("fabricant");
 #   $fabricant =~ s/[^\w ]//g;
    my $country = $query->param("country");
    my $valeur = $query->param("valeur");
    my $location_ou_achat =$query->param("type_de_vente");
    my $type_de_bien = $query->param("type_de_bien");
    my $canton = $query->param("canton");
    my $departement = $query->param("departement");

  #  $valeur =~ s/[^\w ]//g;
    my $buy_price_min = $query->param ("price_min");
  #  $buy_price_min =~ s/[^\w ]//g;    
    my $buy_price_max = $query->param("price_max");
 #   $buy_price_max =~ s/[^\w ]//g;
    my $used = $query->param("used");
    my $string;    
    my $ref_cat;
    my $from;
    my $ref_subcat;
    my $ref_type_de_vente;
    my $ref_canton;
    my $ref_departement;
    my $add;
    my $add2;
    if ($subcategory) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcategory' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $add .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $add .= " and article.ref_categorie = 25";
	    $from .= ", subcategorie_libelle_langue";
    }
    if ($country eq 'Suisse') {
	$add .= " and article.ref_pays = 1";
    } elsif ($country eq 'France') {
	$add .= " and article.ref_pays = 2";
    }
    $lang = lc($lang);
    if ($canton && !($canton eq 'undefined')) {
	$add .= " and article.ref_canton = (SELECT id_canton FROM canton_$lang WHERE nom = '$canton')";
    }
    if ($departement && !($departement eq 'undefined')) {
	$add .= " and article.ref_departement = (SELECT id_departement FROM departement WHERE nom = '$departement')";
    }
    if ($location_ou_achat) {
	$add .= " and article.ref_location_ou_achat = (SELECT ref_location_ou_achat FROM location_ou_achat_libelle_langue, libelle, langue WHERE libelle.libelle = '$location_ou_achat' AND location_ou_achat_libelle_langue.ref_libelle = libelle.id_libelle AND location_ou_achat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
    }
    if ($add eq "") {
	$add2 .= " AND article.ref_categorie = 25";
    }	


    my  ($c)= $db->sqlSelect("count(id_article)",
			   "article,met_en_vente, categorie_libelle_langue $from",
			   "ref_article = id_article AND article.ref_categorie = categorie_libelle_langue.ref_categorie AND met_en_vente.page_principale = 'on' AND ref_statut = '3'  AND quantite > 0 $add $add2");	
	
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
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;page=search_immo&amp;session=$session_id&amp;min_index=$min_index&amp;max_index=$max_index&amp;\"  class=\"menulink2\" ><-$j-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }
        
return $string;    


}
#load search index result
sub doSearchImmoIndexed {
    my $category = $query->param("category");
    my $subcategory = $query->param("type_de_vente");    
    my $fabricant = $query->param("fabricant");
    my $valeur = $query->param("valeur");
    my $buy_price_min = $query->param ("price_min");
    #$buy_price_min =~ s/[^\w ]//g;    
    my $buy_price_max = $query->param("price_max");
    #$buy_price_max =~ s/[^\w ]//g;
    my $type_de_vente =$query->param("type_de_vente");
    my $type_de_bien = $query->param("type_de_bien");
    my $canton = $query->param("canton");
    my $departement = $query->param("departement");
    my $used = $query->param("used");
    my $string;    
    my $select = "DISTINCT article.nom,id_article, prix,pochette,marque";
    my  $from = "article, libelle, langue";
    my  $where = "id_article = id_article ";
    my $ref_cat;
    my $ref_subcat;
    my $ref_type_de_vente;
    my $ref_canton;
    my $ref_departement;
    my $add;
    if ($category) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $where .= " AND article.ref_categorie = 25 AND categorie_libelle_langue.ref_categorie = 25 and  article.ref_categorie = 25";
	    $from .= ", categorie_libelle_langue ";
    }if ($type_de_bien) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$type_de_bien' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $where .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
    if ($type_de_vente) {
	    my @type_vent = $db->sqlSelect("ref_location_ou_achat","location_ou_achat_libelle_langue,libelle,langue","libelle.libelle = '$type_de_vente' and location_ou_achat_libelle_langue.ref_libelle = libelle.id_libelle and location_ou_achat_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_type_de_vente = $type_vent[0];
	    $where .= " AND article.ref_location_ou_achat = $ref_type_de_vente AND location_ou_achat_libelle_langue.ref_location_ou_achat = $ref_type_de_vente";
	    $from .= ", location_ou_achat_libelle_langue";
    }
    if ($canton && !($canton  eq 'undefined')) {
	my @cantons =$db->sqlSelect("id_canton", "canton_fr", "nom = '$canton'");
	$ref_canton = $cantons[0];
	$where .= " AND ref_canton = $ref_canton";
	$from .= ",canton_fr";
    }
    
    if ($departement && !($departement eq 'undefined')) {
	#my @departements = $db->sqlSelect("id_departement", "departement" ,"nom = '$departement'");
	#$ref_departement = $departements[0];
	#$where .= " AND ref_departement = $ref_departement";
	#$from .= ", departement";
    }
    
    
    if ($buy_price_min) {$where .= " AND article.prix >= '$buy_price_min'";	}
    if ($buy_price_max) {$where .= " AND article.prix <= '$buy_price_max'";	}
    my  $total = '0';  
    my  ($d)= $db->sqlSelectMany($select, $from, $where ." AND ref_statut = 3");
    my  $index_start = $query->param ("min_index") ;$index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index") ; $index_end=~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d",$year+1900,$mon+1,$mday;    
    if (!$index_start ) {$index_start = 0;}if (!$index_end ) {$index_end = 40;}
    $string = "<table style=\"border-width:thin; border-style:dotted; border-top-color:#94CEFA;border-right-color:#94CEFA;border-left-color:#94CEFA; border-right-width:2px; border-bottom-color:#94CEFA\" width=\"555\" border=\"0\"><tr bgcolor=\"#DBE4F8\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"120\">$SERVER{'article_name_label'}</td><td align=\"left\" width=\"120\">$SERVER{'fabricant'}</td><td align=\"left\">$SERVER{'article_price_label'}</td><td align=\"left\"></td></tr>";
    my  ($c)= $db->sqlSelectMany($select, $from, $where ." LIMIT $index_start, $index_end");
    while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'price'},$ARTICLE{'image'},$ARTICLE{'fabricant'})=$c->fetchrow()) {
	$string .= "<tr><td align=\"left\"><img alt=\"\" alt=\"\" src=\"$ARTICLE{'image'}\"></td><td align=\"left\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'fabricant'}</td><td align=\"left\">$ARTICLE{'price'}</td><td align=\"left\">$ARTICLE{'depot'}</td></tr>";
    }
    $string .="</table>";    
    return $string;
}


sub doSearchWatch {
    my $category = $query->param("category");
   # $category  =~ s/[^\w ]//g;    
    my $subcategory = $query->param("subcategory");
   # $subcategory  =~ s/[^\w ]//g;    
    my $fabricant = $query->param("fabricant");
#$fabricant =~ s/[^\w ]//g;    
    my $valeur = $query->param("valeur");
   # $valeur =~ s/[^\w ]//g;
    my $buy_price_min = $query->param ("price_min");
    #$buy_price_min =~ s/[^\w ]//g;    
    my $buy_price_max = $query->param("price_max");
   # $buy_price_max =~ s/[^\w ]//g;
    my $used = $query->param("used");
    my $string;    
    my $select = "DISTINCT article.nom";        
    my  $from = "article ";
    my  $where = " id_article = id_article ";
    my $ref_cat;
    my $ref_subcat;
    my $add;
    if ($category) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $where .= " AND article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
	    $from .= ", categorie_libelle_langue ";
    }
    if ($subcategory) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcategory' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $where .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
    if ($fabricant) {if ($fabricant ne '---------') {$where .= " AND article.marque = '$fabricant'";}}
    if ($buy_price_min) {$where .= " AND article.prix >= '$buy_price_min'";}
    if ($buy_price_max) {$where .= " AND article.prix <= '$buy_price_max'";}
    if ($valeur) {$where .= " AND article.nom LIKE '%$valeur%'";}
      if ($used) {
	$from .= ",etat_libelle_langue";
	if ($where ne ''){
		$where .= " AND article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}else {
		$where .= " article.ref_etat = id_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}
    }

    my  $total = '0';    

    my  ($d)= $db->sqlSelect("count(id_article)", $from, $where ." AND ref_statut = '3'");
    
    my  $nb_page = arrondi ($d / 40, 1);my  $min_index = '0';my  $max_index = '40';

    for (my  $i = '0'; $i < $nb_page;$i++) {
	my $n2 = $i %= 10;
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=dosearchwear&amp;min_index=$min_index&amp;session=$session_id&category=$category&fabricant=$fabricant&price_min=$buy_price_min&price_max=$buy_price_max&subcategory=$subcategory\"  class=\"menulink2\" ><-$i-></a>&#160;&nbsp;<img alt=\"\" alt=\"\" src=\"../images/next2.gif\" height=\"13px\" width=\"13px\">";		
	$min_index += 40;	
    }
    return $string;

}
#load search index result
sub doSearchWatchIndexed {    
    my $category = $query->param("category");
   # $category  =~ s/[^\w ]//g;    
    my $subcategory = $query->param("subcategory");
  #  $subcategory  =~ s/[^\w ]//g;    
    my $fabricant = $query->param("fabricant");
  #  $fabricant =~ s/[^\w ]//g;    
    my $valeur = $query->param("valeur");
  #  $valeur =~ s/[^\w ]//g;
    my $buy_price_min = $query->param ("price_min");
  #  $buy_price_min =~ s/[^\w ]//g;    
    my $buy_price_max = $query->param("price_max");
  #  $buy_price_max =~ s/[^\w ]//g;
    my $taille = $query->param("taille");    
    my $used = $query->param("used");
    my $string;    
    my $select = "DISTINCT article.nom,id_article, prix,pochette,marque";
    my  $from = "article, libelle, langue";
    my  $where = "id_article = id_article ";
    my $ref_cat;
    my $ref_subcat;
    my $add;
    if ($category) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $where .= " AND article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
	    $from .= ", categorie_libelle_langue ";
    }
    if ($subcategory) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcategory' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $where .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
    
    if ($taille) {$where .= " AND article.taille = '$taille'";}
    
    if ($valeur) {$where .= " AND article.nom LIKE '%$valeur%'";}    
    
    if ($fabricant) {if ($fabricant ne '---------') {$where .= " AND article.marque = '$fabricant'";}}
    if ($buy_price_min) {$where .= " AND article.prix >= '$buy_price_min'";	}
    if ($buy_price_max) {$where .= " AND article.prix <= '$buy_price_max'";	}
    if ($valeur) {$where .= " AND article.nom LIKE '%$valeur%'";}
         if ($used) {
	$from .= ",etat_libelle_langue";
	if ($where ne ''){
		$where .= " AND article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}else {
		$where .= " article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}
    }
    my  $total = '0';  
    my  ($d)= $db->sqlSelectMany($select, $from, $where ." AND ref_statut = '3'");
    my  $index_start = $query->param ("min_index") ;$index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index") ; $index_end=~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d",$year+1900,$mon+1,$mday;    
    if (!$index_start ) {$index_start = 0;}if (!$index_end ) {$index_end = 40;}
    $string = "<table style=\"border-width:thin; border-style:dotted; border-top-color:#94CEFA;border-right-color:#94CEFA;border-left-color:#94CEFA; border-right-width:2px; border-bottom-color:#94CEFA\" width=\"555\" border=\"0\"><tr bgcolor=\"#DBE4F8\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"120\">$SERVER{'article_name_label'}</td><td align=\"left\" width=\"120\">$SERVER{'fabricant'}</td><td align=\"left\">$SERVER{'article_price_label'}</td><td align=\"left\"></td></tr>";
    my  ($c)= $db->sqlSelectMany($select, $from, $where ." LIMIT $index_start, $index_end");
    while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'price'},$ARTICLE{'image'},$ARTICLE{'fabricant'})=$c->fetchrow()) {
	$string .= "<tr><td align=\"left\"><img alt=\"\" alt=\"\" src=\"$ARTICLE{'image'}\"></td><td align=\"left\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'fabricant'}</td><td align=\"left\">$ARTICLE{'price'}</td><td align=\"left\">$ARTICLE{'depot'}</td></tr>";
    }
    $string .="</table>";    
    return $string;
}
#demain
sub doSearchArt {
    my $category = $query->param('category');
    $category =~ s/\'/\'\'/g;
    my $subcategory = $query->param('subcategory');
    $subcategory =~ s/\'/\'\'/g;
    my $fabricant = $query->param('fabricant');
    $fabricant =~ s/\'/\'\'/g;
    my $valeur = $query->param('valeur');
    $valeur  =~ s/\'/\'\'/g;
    my $buy_price_min = $query->param ("price_min");
    $buy_price_min  =~ s/\'/\'\'/g;
    my $buy_price_max = $query->param("price_max");
    $buy_price_max =~ s/\'/\'\'/g;
    
    my $string;    
    my  $select = "DISTINCT article.nom,id_article,marque,prix, categorie_libelle_langue.ref_categorie, pochette";
    my  $from = "article,categorie_libelle_langue";
    my  $where;
    if ($category) {$where .= "article.ref_categorie = categorie_libelle_langue.ref_categorie AND categorie_libelle_langue.ref_categorie = (SELECT libelle.libelle FROM categorie_libelle_langue, langue, libelle WHERE libelle.libelle = '$category' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";}    
    if ($subcategory) {
	$from .= ",subcategorie_libelle_langue";
	if ($where ne '') {
	    $where .= " AND article.ref_subcategorie = subcategorie_libelle_langue.ref_subcategorie AND subcategorie_ref_subcategorie = (SELECT libelle.libelle FROM subcategorie_libelle_langue, langue, libelle WHERE libelle.libelle = '$subcategory' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}    
	else {
	    $where .= " article.ref_subcategorie = subcategorie_libelle_langue.ref_subcategorie AND subcategorie_libelle.ref_subcategorie = (SELECT libelle.libelle FROM subcategorie_libelle_langue, libelle, langue WHERE subcategorie_libelle.ref_libelle = libelle.id_libelle AND subcategorie_libelle.ref_subcategorie.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}
    }
    if ($fabricant) {$where .= " AND article.marque = '$fabricant'";}
    if ($buy_price_min) {$where .= " AND article.prix >= '$buy_price_min'";}
    if ($buy_price_max) {$where .= " AND article.prix <= '$buy_price_max'";}
    if ($valeur) {$where .= " AND article.nom LIKE '%$valeur%'";}
    
    my  $total = '0';
    
    my  ($d)=$db->sqlSelect("count(article.nom)", $from, $where ." AND ref_statut = '3'");

    my  $nb_page = arrondi ($d / 40, 1);
    my  $min_index = '0';
    my  $max_index = '40';
    my  $username = $query->param("username");
    my  ($cat)= $db->sqlSelect("ref_categorie", "categorie_libelle_langue, libelle, langue", "libelle.libelle = '$category' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my  ($userID)= $db->sqlSelect("id_personne", "personne", "nom_utilisateur = '$username'");
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d",$year+1900,$mon+1,$mday;
    if (!$userID) {$userID = 0;}
    if (!$cat) {$cat = 0;}
    for (my  $i = '0'; $i < $nb_page;$i++) {
	my $n2 = $i %= 10;
	if ($n2 ne '0') {
		#$string .= "<br />";
	}
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=searchwatch&amp;min_index=$min_index&amp;session=$session_id\"  class=\"menulink2\" ><-$i-></a>&#160;&nbsp;<img alt=\"\" alt=\"\" src=\"../images/next2.gif\" height=\"13px\" width=\"13px\">";		
	$min_index += 40;	
    }
    return $string;
}
#load search index result
sub doSearchArtIndexed {
    my $category = shift || '';
    my $subcategory = shift || '';
    my $fabricant = shift || '';
    my $valeur = shift || '';
  #  $valeur =~ s/[^\w ]//g;
    my $buy_price_min = $query->param ("price_min");
 #   $buy_price_min  =~ s/[^\w ]//g;
    my $buy_price_max = $query->param("price_max");
  #  $buy_price_max  =~ s/[^\w ]//g;
    my $from = "article";
    my  $where;

    if ($category) {
        $from .= ", categorie_libelle_langue";
        $where .= "article.ref_categorie = categorie_libelle_langue.ref_categorie AND categorie_libelle_langue.ref_categorie = (SELECT libelle.libelle FROM categorie_libelle_langue, langue, libelle WHERE libelle.libelle = '$category' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";}    
    
    if ($subcategory) {
	$from .= ", subcategorie_libelle_langue";
	if ($where ne '') {
	    $where .= " AND article.ref_subcategorie = subcategorie_libelle_langue.ref_subcategorie AND subcategorie_libelle_langue._ref_subcategorie = (SELECT libelle.libelle FROM subcategorie_libelle_langue, langue, libelle WHERE libelle.libelle = '$subcategory' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}    
	else {
	    $where .= " article.ref_subcategorie = subcategorie_libelle_langue.ref_subcategorie AND subcategorie_libelle_langue.ref_subcategorie = (SELECT subcategorie_libelle_langue.ref_subcategorie FROM subcategorie_libelle_langue, libelle, langue WHERE subcategorie_libelle.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_subcategorie.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}
    }
    if ($fabricant) {$where .= " AND article.marque LIKE '%$fabricant%'";}
    if ($buy_price_min) {$where .= " AND article.prix >= '$buy_price_min'";}
    if ($buy_price_max) {$where .= " AND article.prix <= '$buy_price_max'";}
    if ($valeur) {$where .= " AND article.nom LIKE '%$valeur%'";}
    my $string;    
    my  $select = "DISTINCT article.nom,id_article,marque,prix, categorie_libelle_langue.ref_categorie,pochette";
    $from = "article,subcategorie_libelle_langue,categorie_libelle_langue";
    my  $total = '0';    
    my  ($d)= $db->sqlSelectMany($select, $from, $where ." AND ref_statut = '3'");
    my  $index_start = $query->param ("min_index") ;
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index") ;
    $index_end=~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d",$year+1900,$mon+1,$mday;
    
    if (!$index_start ) {$index_start = 0;}
    if (!$index_end ) {$index_end = 40;}
    $string = "<table style=\"border-width:thin; border-style:dotted; border-top-color:#94CEFA;border-right-color:#94CEFA;border-left-color:#94CEFA; border-right-width:2px; border-bottom-color:#94CEFA\" width=\"555\" border=\"0\"><tr bgcolor=\"#DBE4F8\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"151\">$SERVER{'article_name_label'}</td><td align=\"left\">$SERVER{'fabricant'}</td><td align=\"left\">$SERVER{'article_price_label'}</td><td align=\"left\">$SERVER{'category'}</td></tr>";
    

    my  ($c)= $db->sqlSelectMany($select, $from, $where ." LIMIT $index_start, $index_end");
    
    while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'author'},$ARTICLE{'price'},$ARTICLE{'ref_categorie'},$ARTICLE{'image'})=$c->fetchrow()) {
	if ($ARTICLE{'image'} eq '') {
		##$ARTICLE{'image'} = "../images/blank.gif";
	}
        if ($ARTICLE{'ref_categorie'}) {
            $ARTICLE{'genre'} = $db->sqlSelect ("libelle.libelle","categorie_libelle_langue, libelle, langue","categorie_libelle_langue.ref_categorie = '$ARTICLE{'ref_categorie'}' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
        }
        
	$string .= "<tr><td align=\"left\"><img alt=\"\"  src=\"$ARTICLE{'image'}\"></td><td align=\"left\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'author'}</td><td align=\"left\">$ARTICLE{'price'}</td><td align=\"left\">$ARTICLE{'genre'}</td></tr>";
    }
    $string .="</table>";    
    return $string;
}

sub doSearchJardin {
    my $category = $query->param("category");
   # $category  =~ s/[^\w ]//g;    
    my $subcategory = $query->param("subcategory");
    #$subcategory  =~ s/[^\w ]//g;    
    my $fabricant = $query->param("fabricant");
   # $fabricant =~ s/[^\w ]//g;    
    my $valeur = $query->param("valeur");
  #  $valeur =~ s/[^\w ]//g;
    my $buy_price_min = $query->param ("price_min");
  #  $buy_price_min =~ s/[^\w ]//g;    
    my $buy_price_max = $query->param("price_max");
  #  $buy_price_max =~ s/[^\w ]//g;
    my $used = $query->param("used");
    my $string;    
    my $select = "DISTINCT article.nom";        
    my  $from = "article, libelle, langue";
    my  $where = " id_article = id_article ";
    my $ref_cat;
    my $ref_subcat;
    my $add;
    if ($category) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $where .= " AND article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
	    $from .= ", categorie_libelle_langue ";
    }
    if ($subcategory) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcategory' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
            $where .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
   }
    if ($fabricant) {if ($fabricant ne '---------') {$where .= " AND article.marque = '$fabricant'";}}
    if ($buy_price_min) {$where .= " AND article.prix >= '$buy_price_min'";}
    if ($buy_price_max) {$where .= " AND article.prix <= '$buy_price_max'";}
    if ($valeur) {$where .= " AND article.nom LIKE '%$valeur%'";}
      if ($used) {
	$from .= ",etat_libelle_langue";
	if ($where ne ''){
		$where .= " AND article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}else {
		$where .= " article.ref_etat = id_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}
    }

    my  $total = '0';    
  #  my  ($d)= $db->sqlSelect("count(id_article)", $from, $where ." AND ref_statut = '3'");
    
   # my  $nb_page = arrondi ($d / 40, 1);my  $min_index = '0';my  $max_index = '40';

    #for (my  $i = '0'; $i < $nb_page;$i++) {
	#my $n2 = $i %= 10;
	#$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=dosearchwear&amp;min_index=$min_index&amp;session=$session_id&category=$category&fabricant=$fabricant&price_min=$buy_price_min&price_max=$buy_price_max&subcategory=$subcategory\"  class=\"menulink2\" ><-$i-></a>&#160;&nbsp;<img alt=\"\" alt=\"\" src=\"../images/next2.gif\" height=\"13px\" width=\"13px\">";		
	#$min_index += 40;	
    #}
    return $string;

}
#load search index result
sub doSearchJardinIndexed {
    my $category = $query->param("category");
    my $subcategory = $query->param("subcategory");    
    my $fabricant = $query->param("fabricant");
    my $valeur = $query->param("valeur");
    my $buy_price_min = $query->param ("price_min");
   # $buy_price_min =~ s/[^\w ]//g;    
    my $buy_price_max = $query->param("price_max");
#    $buy_price_max =~ s/[^\w ]//g;
    my $taille = $query->param("taille");    
    my $used = $query->param("used");
    my $string;    
    my $select = "DISTINCT article.nom,id_article, prix,pochette,marque";
    my  $from = "article, libelle, langue";
    my  $where = "id_article = id_article ";
    my $ref_cat;
    my $ref_subcat;
    my $add;
    if ($category) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $where .= " AND article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
	    $from .= ", categorie_libelle_langue ";
    }
    if ($subcategory) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcategory' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $where .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
    
    if ($taille) {$where .= " AND article.taille = '$taille'";}
    
    if ($valeur) {$where .= " AND article.nom LIKE '%$valeur%'";}    
    
    if ($fabricant) {if ($fabricant ne '---------') {$where .= " AND article.marque = '$fabricant'";}}
    if ($buy_price_min) {$where .= " AND article.prix >= '$buy_price_min'";	}
    if ($buy_price_max) {$where .= " AND article.prix <= '$buy_price_max'";	}
    if ($valeur) {$where .= " AND article.nom LIKE '%$valeur%'";}
         if ($used) {
	$from .= ",etat_libelle_langue";
	if ($where ne ''){
		$where .= " AND article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}else {
		$where .= " article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}
    }
    my  $total = '0';  
    my  ($d)= $db->sqlSelectMany($select, $from, $where ." AND ref_statut = '3'");
    my  $index_start = $query->param ("min_index") ;$index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index") ; $index_end=~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d",$year+1900,$mon+1,$mday;    
    if (!$index_start ) {$index_start = 0;}if (!$index_end ) {$index_end = 40;}
    $string = "<table style=\"border-width:thin; border-style:dotted; border-top-color:#94CEFA;border-right-color:#94CEFA;border-left-color:#94CEFA; border-right-width:2px; border-bottom-color:#94CEFA\" width=\"555\" border=\"0\"><tr bgcolor=\"#DBE4F8\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"120\">$SERVER{'article_name_label'}</td><td align=\"left\" width=\"120\">$SERVER{'fabricant'}</td><td align=\"left\">$SERVER{'article_price_label'}</td><td align=\"left\"></td></tr>";
    my  ($c)= $db->sqlSelectMany($select, $from, $where ." LIMIT $index_start, $index_end");
    while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'price'},$ARTICLE{'image'},$ARTICLE{'fabricant'})=$c->fetchrow()) {
	$string .= "<tr><td align=\"left\"><img alt=\"\" alt=\"\" src=\"$ARTICLE{'image'}\"></td><td align=\"left\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'fabricant'}</td><td align=\"left\">$ARTICLE{'price'}</td><td align=\"left\">$ARTICLE{'depot'}</td></tr>";
    }
    $string .="</table>";    
    return $string;
}


sub doSearchSport {
    my $category = $query->param("category");
   # $category  =~ s/[^\w ]//g;    
    my $subcategory = $query->param("subcategory");
    #$subcategory  =~ s/[^\w ]//g;    
    my $fabricant = $query->param("fabricant");
 #   $fabricant =~ s/[^\w ]//g;    
    my $valeur = $query->param("valeur");
 #   $valeur =~ s/[^\w ]//g;
    my $buy_price_min = $query->param ("price_min");
 #   $buy_price_min =~ s/[^\w ]//g;    
    my $buy_price_max = $query->param("price_max");
 #   $buy_price_max =~ s/[^\w ]//g;
    my $used = $query->param("used");
    my $string;    
    my $select = "DISTINCT article.nom";        
    my  $from = "article, libelle, langue";
    my  $where = " id_article = id_article ";
    my $ref_cat;
    my $ref_subcat;
    my $add;
    if ($category) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $where .= " AND article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
	    $from .= ", categorie_libelle_langue ";
    }
    if ($subcategory) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcategory' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
            $where .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
   }
    if ($fabricant) {if ($fabricant ne '---------') {$where .= " AND article.marque = '$fabricant'";}}
    if ($buy_price_min) {$where .= " AND article.prix >= '$buy_price_min'";}
    if ($buy_price_max) {$where .= " AND article.prix <= '$buy_price_max'";}
    if ($valeur) {$where .= " AND article.nom LIKE '%$valeur%'";}
      if ($used) {
	$from .= ",etat_libelle_langue";
	if ($where ne ''){
		$where .= " AND article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}else {
		$where .= " article.ref_etat = id_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}
    }

    my  $total = '0';    
    my  ($d)= $db->sqlSelect("count(id_article)", $from, $where ." AND ref_statut = '3'");
    
    my  $nb_page = arrondi ($d / 40, 1);my  $min_index = '0';my  $max_index = '40';

    for (my  $i = '0'; $i < $nb_page;$i++) {
	my $n2 = $i %= 10;
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=dosearchwear&amp;min_index=$min_index&amp;session=$session_id&category=$category&fabricant=$fabricant&price_min=$buy_price_min&price_max=$buy_price_max&subcategory=$subcategory\"  class=\"menulink2\" ><-$i-></a>&#160;&nbsp;<img alt=\"\" alt=\"\" src=\"../images/next2.gif\" height=\"13px\" width=\"13px\">";		
        $min_index += 40;	
    }
    return $string;

}
#load search index result
sub doSearchSportIndexed {
    my $category = $query->param("category");
    my $subcategory = $query->param("subcategory");    
    my $fabricant = $query->param("fabricant");
    my $valeur = $query->param("valeur");
    my $buy_price_min = $query->param ("price_min");
   # $buy_price_min =~ s/[^\w ]//g;    
    my $buy_price_max = $query->param("price_max");
  #  $buy_price_max =~ s/[^\w ]//g;
    my $taille = $query->param("taille");	    
    my $used = $query->param("used");
    my $string;    
    my $select = "DISTINCT article.nom,id_article, prix,pochette,marque";
    my  $from = "article, libelle, langue";
    my  $where = "id_article = id_article ";
    my $ref_cat;
    my $ref_subcat;
    my $add;
    if ($category) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $where .= " AND article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
	    $from .= ", categorie_libelle_langue ";
    }
    if ($subcategory) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcategory' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $where .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
    
    if ($taille) {$where .= " AND article.taille = '$taille'";}
    
    if ($valeur) {$where .= " AND article.nom LIKE '%$valeur%'";}    
    
    if ($fabricant) {if ($fabricant ne '---------') {$where .= " AND article.marque = '$fabricant'";}}
    if ($buy_price_min) {$where .= " AND article.prix >= '$buy_price_min'";	}
    if ($buy_price_max) {$where .= " AND article.prix <= '$buy_price_max'";	}
    if ($valeur) {$where .= " AND article.nom LIKE '%$valeur%'";}
         if ($used) {
	$from .= ",etat_libelle_langue";
	if ($where ne ''){
		$where .= " AND article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}else {
		$where .= " article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}
    }
    my  $total = '0';  
    my  ($d)= $db->sqlSelectMany($select, $from, $where ." AND ref_statut = '3'");
    my  $index_start = $query->param ("min_index") ;$index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index") ; $index_end=~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d",$year+1900,$mon+1,$mday;    
    if (!$index_start ) {$index_start = 0;}if (!$index_end ) {$index_end = 40;}
    $string = "<table style=\"border-width:thin; border-style:dotted; border-top-color:#94CEFA;border-right-color:#94CEFA;border-left-color:#94CEFA; border-right-width:2px; border-bottom-color:#94CEFA\" width=\"555\" border=\"0\"><tr bgcolor=\"#DBE4F8\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"120\">$SERVER{'article_name_label'}</td><td align=\"left\" width=\"120\">$SERVER{'fabricant'}</td><td align=\"left\">$SERVER{'article_price_label'}</td><td align=\"left\"></td></tr>";
    my  ($c)= $db->sqlSelectMany($select, $from, $where ." LIMIT $index_start, $index_end");
    while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'price'},$ARTICLE{'image'},$ARTICLE{'fabricant'})=$c->fetchrow()) {
	$string .= "<tr><td align=\"left\"><img alt=\"\" alt=\"\" src=\"$ARTICLE{'image'}\"></td><td align=\"left\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'fabricant'}</td><td align=\"left\">$ARTICLE{'price'}</td><td align=\"left\">$ARTICLE{'depot'}</td></tr>";
    }
    $string .="</table>";    
    return $string;
}


sub searchCigares {
    my $category = $query->param('category');
  #  $category  =~ s/[^\w ]//g;    
    my $subcategory = $query->param('subcategory');
  #  $subcategory  =~ s/[^\w ]//g;    
    my $fabricant = $query->param('fabricant');
 #   $fabricant =~ s/[^\w ]//g;    
    my $valeur = $query->param('valeur');
  #  $valeur =~ s/[^\w ]//g;
    my $content;
    $session = new CGI::Session("driver:File", $session_id, {Directory=>"$session_dir"});
    my $level = $session->param("level");
	if ($level eq '2') {
	    $LINK{'admin'} = "<a href=\"javascript:void(0)\" class=\"menulink\"  onclick=\"window.open('/cgi-bin/recordz.cgi?lang=$lang&amp;page=cms_manage_article&amp;session=$session_id;','MyWindow','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=no,width=800,height=600,left=20,top=20')\">Admin</a>";
	}
	else {
	    $LINK{'admin'} = "";
	}
    
    
    my  $string = doSearchCigares ($category, $subcategory,$fabricant, $valeur);
    my  $string2 = doSearchCigaresIndexed  ($category, $subcategory,$fabricant, $valeur);
    my $string4 = weekNews ();
    open (FILE, "<$dir/dosearchcigares.html") or die "cannot open file $dir/dosearchcigares.html";
    my $menu = loadMenu();
    my $cats = getCat();
    while (<FILE>) {	
	s/\$LABEL{'([\w]+)'}/ exists $SERVER{$1} ? $SERVER{$1} : $1 /eg; 
	s/\$LANG/$lang/g;
	s/\$ERROR{'([\w]+)'}//g;
	s/\$ARTICLE{'index_table'}/$string/g;
	#s/\$ARTICLE{'news'}//g;
	s/\$OPTIONS{'categories'}/$cats/g;
	s/\$LINK{'admin'}/$LINK{'admin'}/g;
	s/\$SESSIONID/$session_id/g;
	s/\$ARTICLE{'main_menu'}/$menu/g;
	s/\$ARTICLE{'search'}/$string2/g;
	s/\$ARTICLE{'week_news'}/$string4/g;
	$content .= $_;	
    }
	$content = Compress::Zlib::memGzip($content)  if $can_do_gzip; ;
	print "Content-Length: ", length($content) , "\n";
	print "Content-Encoding: gzip\n" ;
	print "Content-Type: text/html\n\n"; 
	print $content;
        close (FILE);	
	
}

sub doSearchCigares {
    my $category = shift || '';
  #  $category  =~ s/[^\w ]//g;    
    my $subcategory = shift || '';
  #  $subcategory  =~ s/[^\w ]//g;    
    my $fabricant = shift || '';
  #  $fabricant =~ s/[^\w ]//g;    
    my $valeur = shift || '';
  #  $valeur =~ s/[^\w ]//g;
    my $buy_price_min = $query->param ("price_min");
  #  $buy_price_min =~ s/[^\w ]//g;
    my $buy_price_max = $query->param("price_max");
  #  $buy_price_max =~ s/[^\w ]//g;
    my $string;    
    my $select = "DISTINCT article.nom";        
    my  $from = "article";
    my $where;
    
    if ($category) {
        $from .= ", categorie_libelle_langue";
        $where .= "article.ref_categorie = categorie_libelle_langue.ref_categorie AND categorie_libelle_langue.ref_categorie = (SELECT categorie_libelle_langue.ref_categorie FROM categorie_libelle_langue, langue, libelle WHERE libelle.libelle = '$category' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue.id_langue AND langue.key = '$lang')";}    
    if ($subcategory) {
	$from .= ",subcategorie_libelle";
	if ($where ne '') {
	    $where .= " AND article.ref_subcategorie = subcategorie_libelle.ref_subcategorie AND subcategorie_ref_subcategorie = (SELECT libelle.libelle FROM subcategorie_libelle_langue, langue, libelle WHERE libelle.libelle = '$subcategory' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue.id_langue AND langue.key = '$lang')";
	}else {
	    $where .= " article.ref_subcategorie = subcategorie_libelle.ref_subcategorie AND subcategorie_libelle.ref_subcategorie = (SELECT libelle.libelle FROM subcategorie_libelle_langue, libelle, langue WHERE subcategorie_libelle.ref_libelle = libelle.id_libelle AND subcategorie_libelle.ref_subcategorie.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}
    }

    if ($fabricant) {if ($fabricant ne '---------') {$where .= " AND article.marque = '$fabricant'";}}
    if ($buy_price_min) {$where .= " AND article.prix >= '$buy_price_min'";}
    if ($buy_price_max) {$where .= " AND article.prix <= '$buy_price_max'";}
    if ($valeur) {$where .= " AND article.nom LIKE '%$valeur%'";}
    
    my  $total = '0';    
    my  ($d)= sqlSelect("count(article.id_article)", $from, $where ." AND ref_statut = '3'");
        my  $nb_page = arrondi ($d / 40, 1);my  $min_index = '0';my  $max_index = '40';

    for (my  $i = '0'; $i < $nb_page;$i++) {
	my $n2 = $i %= 10;
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=dosearchcigares&amp;min_index=$min_index&amp;session=$session_id&category=$category&fabricant=$fabricant&price_min=$buy_price_min&price_max=$buy_price_max\"  class=\"menulink2\" ><-$i-></a>&#160;&nbsp;<img alt=\"\" alt=\"\" src=\"../images/next2.gif\" height=\"13px\" width=\"13px\">";		
	$min_index += 40;	
    }
    return $string;
}
#load search index result
sub doSearchCigaresIndexed {
    my $category = shift || '';
  #  $category  =~ s/[^\w ]//g;    
    my $subcategory = shift || '';
 #   $subcategory  =~ s/[^\w ]//g;    
    my $fabricant = shift || '';
  #  $fabricant =~ s/[^\w ]//g;    
    my $valeur = shift || '';
  #  $valeur =~ s/[^\w ]//g;
    my $buy_price_min = $query->param ("price_min");
  #  $buy_price_min =~ s/[^\w ]//g;
    my $buy_price_max = $query->param("price_max");
  #  $buy_price_max =~ s/[^\w ]//g;
    my $string;
    my $select = "DISTINCT article.nom,id_article, prix,pochette,marque";
    my  $from = "article";
    my  $where;
    
    if ($category) {
        $from .= ", categorie_libelle_langue";
        $where .= "article.ref_categorie = categorie_libelle_langue.ref_categorie AND categorie_libelle_langue.ref_categorie = (SELECT categorie_libelle_langue.ref_categorie FROM categorie_libelle_langue, langue, libelle WHERE libelle.libelle = '$category' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";}    
    if ($subcategory) {
	$from .= ", subcategorie_libelle";
	if ($where ne '') {
	    $where .= " AND article.ref_subcategorie = subcategorie_libelle.ref_subcategorie AND subcategorie_ref_subcategorie = (SELECT subcategorie_libelle_langue.ref_subcategorie FROM subcategorie_libelle_langue, langue, libelle WHERE libelle.libelle = '$subcategory' AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}else {
	    $where .= " article.ref_subcategorie = subcategorie_libelle.ref_subcategorie AND subcategorie_libelle.ref_subcategorie = (SELECT subcategorie_libelle.ref_subcategorie FROM subcategorie_libelle_langue, libelle, langue WHERE subcategorie_libelle.ref_libelle = libelle.id_libelle AND subcategorie_libelle.ref_subcategorie.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}
    } 
    if ($fabricant) {if ($fabricant ne '---------') {$where .= " AND article.marque = '$fabricant'";}}
    if ($buy_price_min) {$where .= " AND article.prix >= '$buy_price_min'";}
    if ($buy_price_max) {$where .= " AND article.prix <= '$buy_price_max'";}
    if ($valeur) {$where .= " AND article.nom LIKE '%$valeur%'";}
    my  $total = '0';  
    my  ($d)= sqlSelectMany($select, $from, $where ." AND ref_statut = '3'");
    my  $index_start = $query->param ("min_index") ;$index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index") ; $index_end=~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d",$year+1900,$mon+1,$mday;    
    if (!$index_start ) {$index_start = 0;}if (!$index_end ) {$index_end = 40;}
    $string = "<table style=\"border-width:thin; border-style:dotted;border-top-color:#94CEFA;border-right-color:#94CEFA;border-left-color:#94CEFA; border-right-width:2px; border-bottom-color:#94CEFA\" width=\"555\" border=\"0\"><tr bgcolor=\"#DBE4F8\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"120\">$SERVER{'article_name_label'}</td><td align=\"left\" width=\"120\">$SERVER{'fabricant'}</td><td align=\"left\">$SERVER{'article_price_label'}</td><td align=\"left\"></td></tr>";
    my  ($c)= sqlSelectMany($select, $from, $where ." LIMIT $index_start, $index_end");
    while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'price'},$ARTICLE{'image'},$ARTICLE{'fabricant'})=$c->fetchrow()) {
	$string .= "<tr><td align=\"left\"><img alt=\"\" alt=\"\" src=\"$ARTICLE{'image'}\"></td><td align=\"left\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'fabricant'}</td><td align=\"left\">$ARTICLE{'price'}</td><td align=\"left\">$ARTICLE{'depot'}</td></tr>";
    }
    $string .="</table>";    
    return $string;
}

sub searchWear {
    my $category = shift || '';
    $category  =~ s/[^\w ]//g;    
    my $subcategory = shift ||  '';
    $subcategory  =~ s/[^\w ]//g;    
    my $fabricant = shift || '';
    $fabricant =~ s/[^\w ]//g;    
    my $valeur = shift ||  '';
    $valeur =~ s/[^\w ]//g;
    my $content;
    $session = new CGI::Session("driver:File", $session_id, {Directory=>"$session_dir"});
    my $level = $session->param("level");
	if ($level eq '2') {
	    $LINK{'admin'} = "<a href=\"javascript:void(0)\" class=\"menulink\"  onclick=\"window.open('/cgi-bin/recordz.cgi?lang=$lang&amp;page=cms_manage_article&amp;session=$session_id;','MyWindow','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=no,width=800,height=600,left=20,top=20')\">Admin</a>";
	}
	else {
	    $LINK{'admin'} = "";
	}
    
    
    my  $string = doSearchWear ($category,$subcategory,$fabricant, $valeur);
    my  $string2 = doSearchWearIndexed ($category,$subcategory,$fabricant, $valeur);
    
    open (FILE, "<$dir/dosearchwear.html") or die "cannot open file $dir/dosearchwear.html";
    my $menu = $lp->loadMenu();
    my $cats = $lp->getCat();
    my $categories = $lp->loadCategories();
    while (<FILE>) {	
	s/\$LABEL{'([\w]+)'}/ exists $SERVER{$1} ? $SERVER{$1} : $1 /eg; 
	s/\$LANG/$lang/g;
	s/\$ERROR{'([\w]+)'}//g;
	s/\$ARTICLE{'index_table'}/$string/g;
	#s/\$ARTICLE{'news'}//g;
	s/\$OPTIONS{'categories'}/$categories/g;
	s/\$LINK{'admin'}/$LINK{'admin'}/g;
	s/\$SESSIONID/$session_id/g;
	s/\$ARTICLE{'main_menu'}/$menu/g;
	s/\$ARTICLE{'search'}/$string2/g;
    
	$content .= $_;	
    }
	$content = Compress::Zlib::memGzip($content)  if $can_do_gzip; ;
	print "Content-Length: ", length($content) , "\n";
	print "Content-Encoding: gzip\n" ;
	print "Content-Type: text/html\n\n"; 
	print $content;
        close (FILE);	
}

sub searchInfo {
    my $category = $query->param("category");
    $category  =~ s/[^\w ]//g;    
    my $subcategory = $query->param("subcategory");
    $subcategory  =~ s/[^\w ]//g;    
    my $fabricant = $query->param("fabricant");
    $fabricant =~ s/[^\w ]//g;    
    my $valeur = $query->param("valeur");
    $valeur =~ s/[^\w ]//g;
    my $content;
    $session = new CGI::Session("driver:File", $session_id, {Directory=>"$session_dir"});
    my $level = $session->param("level");
	if ($level eq '2') {
	    $LINK{'admin'} = "<a href=\"javascript:void(0)\" class=\"menulink\"  onclick=\"window.open('/cgi-bin/recordz.cgi?lang=$lang&amp;page=cms_manage_article&amp;session=$session_id;','MyWindow','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=no,width=800,height=600,left=20,top=20')\">Admin</a>";
	}
	else {
	    $LINK{'admin'} = "";
	}
    
    
    my  $string = doSearchInfo ($category, $subcategory,$fabricant, $valeur);
    my  $string2 = doSearchInfoIndexed ($category, $subcategory,$fabricant, $valeur);

    my $string4 = weekNews ();
    open (FILE, "<$dir/dosearchtv.html") or die "cannot open file $dir/dosearchtv.html";
    my $menu = loadMenu();
    my $cats = getCat();
    while (<FILE>) {	
	s/\$LABEL{'([\w]+)'}/ exists $SERVER{$1} ? $SERVER{$1} : $1 /eg; 
	s/\$LANG/$lang/g;
	s/\$ERROR{'([\w]+)'}//g;
	s/\$ARTICLE{'index_table'}/$string/g;
	#s/\$ARTICLE{'news'}//g;
	s/\$OPTIONS{'categories'}/$cats/g;
	s/\$LINK{'admin'}/$LINK{'admin'}/g;
	s/\$SESSIONID/$session_id/g;
	s/\$ARTICLE{'main_menu'}/$menu/g;
	s/\$ARTICLE{'search'}/$string2/g;
	s/\$ARTICLE{'week_news'}/$string4/g;
	$content .= $_;	
    }
	$content = Compress::Zlib::memGzip($content)  if $can_do_gzip; ;
	print "Content-Length: ", length($content) , "\n";
	print "Content-Encoding: gzip\n" ;
	print "Content-Type: text/html\n\n"; 
	print $content;
        close (FILE);	
}
sub searchInstruments {

    my $category = $query->param("category");
    #$category  =~ s/[^\w ]//g;    
    my $subcategory = $query->param("subcategory");
    #$subcategory  =~ s/[^\w ]//g;    
    my $fabricant = $query->param("fabricant");
    #$fabricant =~ s/[^\w ]//g;    
    my $valeur = $query->param("valeur");
    #$valeur =~ s/[^\w ]//g;
    my $content;
    $session = new CGI::Session("driver:File", $session_id, {Directory=>"$session_dir"});
    my  $string = doSearchInstruments ($category, $subcategory,$fabricant, $valeur);
    my  $string2 = doSearchInstrumentsIndexed ($category, $subcategory, $fabricant, $valeur);

  my $categories = $lp->loadCategories();
    open (FILE, "<$dir/dosearchlingerie.html") or die "cannot open file $dir/dosearchlingerie.html";
    my $menu = loadMenu();
    
    while (<FILE>) {	
	s/\$LABEL{'([\w]+)'}/ exists $SERVER{$1} ? $SERVER{$1} : $1 /eg; 
	s/\$LANG/$lang/g;
	s/\$ERROR{'([\w]+)'}//g;
	s/\$ARTICLE{'index_table'}/$string/g;
	s/\$OPTIONS{'categories'}/$categories/g;
	
	s/\$SESSIONID/$session_id/g;
	s/\$ARTICLE{'main_menu'}/$menu/g;
	s/\$ARTICLE{'search'}/$string2/g;
	$content .= $_;	
    }
	$content = Compress::Zlib::memGzip($content)  if $can_do_gzip; ;
	print "Content-Length: ", length($content) , "\n";
	print "Content-Encoding: gzip\n" ;
	print "Content-Type: text/html\n\n"; 
	print $content;
        close (FILE);	    
}

sub searchCollection {
    my $category = $query->param("category");
    #$category  =~ s/[^\w ]//g;    
    my $subcategory = $query->param("subcat");
    #$subcategory  =~ s/[^\w ]//g;    
    my $fabricant = $query->param("fabricant");
    #$fabricant =~ s/[^\w ]//g;    
    my $valeur = $query->param("valeur");
    #$valeur =~ s/[^\w ]//g;
    my $content;
    $session = new CGI::Session("driver:File", $session_id, {Directory=>"$session_dir"});
    my  $string = doSearchCollection ($category, $subcategory,$fabricant, $valeur);
    my  $string2 = doSearchCollectionIndexed ($category, $subcategory, $fabricant, $valeur);
    my $categories = $lp->loadCategories();
  
    open (FILE, "<$dir/dosearchcollection.html") or die "cannot open file $dir/dosearchcollection.html";
    my $menu = loadMenu();
    
    while (<FILE>) {	
	s/\$LABEL{'([\w]+)'}/ exists $SERVER{$1} ? $SERVER{$1} : $1 /eg; 
	s/\$LANG/$lang/g;
	s/\$ERROR{'([\w]+)'}//g;
	s/\$ARTICLE{'index_table'}/$string/g;
	s/\$OPTIONS{'categories'}/$categories/g;
	
	s/\$SESSIONID/$session_id/g;
	s/\$ARTICLE{'main_menu'}/$menu/g;
	s/\$ARTICLE{'search'}/$string2/g;
	$content .= $_;	
    }
	$content = Compress::Zlib::memGzip($content)  if $can_do_gzip; ;
	print "Content-Length: ", length($content) , "\n";
	print "Content-Encoding: gzip\n" ;
	print "Content-Type: text/html\n\n"; 
	print $content;
        close (FILE);	    
    
}
sub doSearchInstruments {
    my $category = shift  || '';
    #$category  =~ s/[^\w ]//g;    
    my $subcategory = $query->param("subcategory");
    #$subcategory  =~ s/[^\w ]//g;    
    my $fabricant  = shift  || '';
    #$fabricant =~ s/[^\w ]//g;    
    my $valeur  = shift  || '';
    #$valeur =~ s/[^\w ]//g;

    my $buy_price_min = $query->param ("price_min");
    #$buy_price_min =~ s/[^\w ]//g;    
    my $buy_price_max = $query->param("price_max");
    #$buy_price_max =~ s/[^\w ]//g;
    my $used = $query->param("used");
    my $string;    
    my $select = "DISTINCT article.nom";        
    my  $from = "article";
    my  $where = "";
    my $ref_cat;
    my $ref_subcat;
    if ($category) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $where .= " article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
	    $from .= ", categorie_libelle_langue ";
    }
    if ($subcategory) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcategory' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
            $where .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
   }

    if ($buy_price_min) {$where .= " AND article.prix >= '$buy_price_min'";}
    if ($buy_price_max) {$where .= " AND article.prix <= '$buy_price_max'";}
    if ($valeur) {$where .= " AND article.nom LIKE '%$valeur%'";}
    
        if ($used) {
	$from .= ",etat_libelle_langue";
	if ($where ne ''){
		$where .= " AND article.ref_etat = id_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}else {
		$where .= " article.ref_etat = id_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}

    }

    my  $total = '0';    
    my  ($d)= $db->sqlSelect("count(id_article)", $from, $where ." AND ref_statut = '3'");
    
    my  $nb_page = arrondi ($d / 40, 1);my  $min_index = '0';my  $max_index = '40';

    for (my  $i = '0'; $i < $nb_page;$i++) {
	my $n2 = $i %= 10;
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=dosearchinstruments&amp;min_index=$min_index&amp;session=$session_id&category=$category&fabricant=$fabricant&price_min=$buy_price_min&price_max=$buy_price_max\"  class=\"menulink2\" ><-$i-></a>&#160;&nbsp;<img alt=\"\" alt=\"\" src=\"../images/next2.gif\" height=\"13px\" width=\"13px\">";		
	$min_index += 40;	
    }
    return $string;
}
#load search index result
sub doSearchInstrumentsIndexed {
    my $category = shift || '';
    #$category  =~ s/[^\w ]//g;    
    my $subcategory = $query->param("subcategory");
    #$subcategory  =~ s/[^\w ]//g;    
    my $fabricant  = shift || '';
    #$fabricant =~ s/[^\w ]//g;    
    my $valeur  = shift || '';
    #$valeur =~ s/[^\w ]//g;
    my $buy_price_min = $query->param ("price_min");
    #$buy_price_min =~ s/[^\w ]//g;    
    my $buy_price_max = $query->param("price_max");
    #$buy_price_max =~ s/[^\w ]//g;
    my $used = $query->param("used");
    my $string; my $select = "DISTINCT article.nom,id_article, prix,pochette,marque";
    my  $from = "article";my  $where;
    my $ref_cat;
    my $ref_subcat;

    if ($category) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $where .= "  article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
	    $from .= ", categorie_libelle_langue ";
    }
    if ($subcategory) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcategory' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
            $where .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
   }

    
    if ($buy_price_min) {$where .= " AND article.prix >= '$buy_price_min'";	}
    if ($buy_price_max) {$where .= " AND article.prix <= '$buy_price_max'";	}
    if ($valeur) {$where .= " AND article.nom LIKE '%$valeur%'";}    
  
        if ($used) {
	    $from .= ",etat_libelle_langue";
	if ($where ne ''){
		$where .= " AND article.ref_etat = id_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}else {
		$where .= " article.ref_etat = id_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}
	}

    my  $total = '0';  
    my  ($d)= $db->sqlSelectMany($select, $from, $where ." AND ref_statut = '3'");
    my  $index_start = $query->param ("min_index") ;$index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index") ; $index_end=~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d",$year+1900,$mon+1,$mday;    
    if (!$index_start ) {$index_start = 0;}if (!$index_end ) {$index_end = 40;}
    $string = "<table style=\"border-width:thin; border-style:dotted; border-top-color:#94CEFA;border-right-color:#94CEFA;border-left-color:#94CEFA; border-right-width:2px; border-bottom-color:#94CEFA\" width=\"555\" border=\"0\"><tr bgcolor=\"#DBE4F8\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"120\">$SERVER{'article_name_label'}</td><td align=\"left\" width=\"120\">$SERVER{'fabricant'}</td><td align=\"left\">$SERVER{'article_price_label'}</td><td align=\"left\"></td></tr>";
    my  ($c)= $db->sqlSelectMany($select, $from, $where ." LIMIT $index_start, $index_end");
    while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'price'},$ARTICLE{'image'},$ARTICLE{'fabricant'})=$c->fetchrow()) {
	$string .= "<tr><td align=\"left\"><img alt=\"\" alt=\"\" src=\"$ARTICLE{'image'}\"></td><td align=\"left\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'fabricant'}</td><td align=\"left\">$ARTICLE{'price'}</td><td align=\"left\">$ARTICLE{'depot'}</td></tr>";
    }
    $string .="</table>";    
    return $string;
}

sub doSearchCollection {
    my $category = shift  || '';
    $category  =~ s/[^\w ]//g;    
    my $subcategory = $query->param("subcat");
    
    my $fabricant  = shift  || '';
    $fabricant =~ s/[^\w ]//g;    
    my $valeur  = shift  || '';
    $valeur =~ s/[^\w ]//g;

    my $buy_price_min = $query->param ("price_min");
    $buy_price_min =~ s/[^\w ]//g;    
    my $buy_price_max = $query->param("price_max");
    $buy_price_max =~ s/[^\w ]//g;
    my $used = $query->param("used");
    my $string;    
    my $select = "DISTINCT article.nom";        
    my  $from = "article";
    my  $where = "";
    my $ref_subcat;
    if (!$category) {
	    $where .= " article.ref_categorie = 18 AND categorie_libelle_langue.ref_categorie = 18 and  article.ref_categorie = 18";
	    $from .= ", categorie_libelle_langue ";
    }
    if ($subcategory) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcategory' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
            $where .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
   }

    if ($buy_price_min) {$where .= " AND article.prix >= '$buy_price_min'";}
    if ($buy_price_max) {$where .= " AND article.prix <= '$buy_price_max'";}
    if ($valeur) {$where .= " AND article.nom LIKE '%$valeur%'";}
    
        if ($used) {
	$from .= ",etat_libelle_langue";
	if ($where ne ''){
		$where .= " AND article.ref_etat = id_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}else {
		$where .= " article.ref_etat = id_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}

    }

    my  $total = '0';    
    my  ($d)= $db->sqlSelect("count(id_article)", $from, $where ." AND ref_statut = '3'");
    
    my  $nb_page = arrondi ($d / 40, 1);my  $min_index = '0';my  $max_index = '40';

    for (my  $i = '0'; $i < $nb_page;$i++) {
	my $n2 = $i %= 10;
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=dosearchinstruments&amp;min_index=$min_index&amp;session=$session_id&category=$category&fabricant=$fabricant&price_min=$buy_price_min&price_max=$buy_price_max\"  class=\"menulink2\" ><-$i-></a>&#160;&nbsp;<img alt=\"\" alt=\"\" src=\"../images/next2.gif\" height=\"13px\" width=\"13px\">";		
	$min_index += 40;	
    }
    return $string;
}
#load search index result
sub doSearchCollectionIndexed {
    my $category = shift || '';
    $category  =~ s/[^\w ]//g;    
    my $subcategory = $query->param("subcat");
    
    my $fabricant  = shift || '';
    $fabricant =~ s/[^\w ]//g;    
    my $valeur  = shift || '';
    $valeur =~ s/[^\w ]//g;
    my $buy_price_min = $query->param ("price_min");
    $buy_price_min =~ s/[^\w ]//g;    
    my $buy_price_max = $query->param("price_max");
    $buy_price_max =~ s/[^\w ]//g;
    my $used = $query->param("used");
    my $string; my $select = "DISTINCT article.nom,id_article, prix,pochette,marque";
    my  $from = "article";my  $where;
    my $ref_subcat;

    if (!$category) {
	    $where .= "  article.ref_categorie = 18 AND categorie_libelle_langue.ref_categorie = 18 and  article.ref_categorie = 18";
	    $from .= ", categorie_libelle_langue ";
    }
    if ($subcategory) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcategory' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
            $where .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
   }

    
    if ($buy_price_min) {$where .= " AND article.prix >= '$buy_price_min'";	}
    if ($buy_price_max) {$where .= " AND article.prix <= '$buy_price_max'";	}
    if ($valeur) {$where .= " AND article.marque LIKE '%$valeur%'";}    
  
        if ($used) {
	    $from .= ",etat_libelle_langue";
	if ($where ne ''){
		$where .= " AND article.ref_etat = id_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}else {
		$where .= " article.ref_etat = id_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}
	}

    my  $total = '0';  
    my  ($d)= $db->sqlSelectMany($select, $from, $where ." AND ref_statut = '3'");
    my  $index_start = $query->param ("min_index") ;$index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index") ; $index_end=~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d",$year+1900,$mon+1,$mday;    
    if (!$index_start ) {$index_start = 0;}if (!$index_end ) {$index_end = 40;}
    $string = "<table style=\"border-width:thin; border-style:dotted; border-top-color:#94CEFA;border-right-color:#94CEFA;border-left-color:#94CEFA; border-right-width:2px; border-bottom-color:#94CEFA\" width=\"555\" border=\"0\"><tr bgcolor=\"#DBE4F8\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"120\">$SERVER{'article_name_label'}</td><td align=\"left\" width=\"120\">$SERVER{'fabricant'}</td><td align=\"left\">$SERVER{'article_price_label'}</td><td align=\"left\"></td></tr>";
    my  ($c)= $db->sqlSelectMany($select, $from, $where ." LIMIT $index_start, $index_end");
    while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'price'},$ARTICLE{'image'},$ARTICLE{'fabricant'})=$c->fetchrow()) {
	$string .= "<tr><td align=\"left\"><img alt=\"\" alt=\"\" src=\"$ARTICLE{'image'}\"></td><td align=\"left\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'fabricant'}</td><td align=\"left\">$ARTICLE{'price'}</td><td align=\"left\">$ARTICLE{'depot'}</td></tr>";
    }
    $string .="</table>";    
    return $string;
}

sub searchLingerie {
    my $category = $query->param("category");
    $category  =~ s/[^\w ]//g;    
    my $subcategory = $query->param("subcategory");
    $category  =~ s/[^\w ]//g;    
    my $fabricant = $query->param("fabricant");
    $fabricant =~ s/[^\w ]//g;    
    my $valeur = $query->param("valeur");
    $valeur =~ s/[^\w ]//g;

    my $content;
    $session = new CGI::Session("driver:File", $session_id, {Directory=>"$session_dir"});
    my  $string = doSearchLingerie ($category, $subcategory,$fabricant, $valeur);
    my  $string2 = doSearchLingerieIndexed ($category, $subcategory,$fabricant, $valeur);

    
    open (FILE, "<$dir/dosearchlingerie.html") or die "cannot open file $dir/dosearchlingerie.html";
    my $menu = $lp->loadMenu();
    my $categories = $lp->loadCategories();
    my $cats = $lp->getCat();
    while (<FILE>) {	
	s/\$LABEL{'([\w]+)'}/ exists $SERVER{$1} ? $SERVER{$1} : $1 /eg; 
	s/\$LANG/$lang/g;
	s/\$ERROR{'([\w]+)'}//g;
	s/\$ARTICLE{'index_table'}/$string/g;
	#s/\$ARTICLE{'news'}//g;
	s/\$OPTIONS{'categories'}/$categories/g;
	s/\$SESSIONID/$session_id/g;
	s/\$ARTICLE{'main_menu'}/$menu/g;
	s/\$ARTICLE{'search'}/$string2/g;
    
	$content .= $_;	
    }
	$content = Compress::Zlib::memGzip($content)  if $can_do_gzip; ;
	print "Content-Length: ", length($content) , "\n";
	print "Content-Encoding: gzip\n" ;
	print "Content-Type: text/html\n\n"; 
	print $content;
        close (FILE);	
}

sub searchAnimal {
    my $category = $query->param("category");
    $category  =~ s/[^\w ]//g;    
    my $subcategory = $query->param("subcategory");
    $category  =~ s/[^\w ]//g;    
    my $fabricant = $query->param("fabricant");
    $fabricant =~ s/[^\w ]//g;    
    my $valeur = $query->param("valeur");
    $valeur =~ s/[^\w ]//g;
    my $content;
    $session = new CGI::Session("driver:File", $session_id, {Directory=>"$session_dir"});
    my  $string = doSearchAnimal ($category, $subcategory,$fabricant, $valeur);
    my  $string2 = doSearchAnimalIndexed ($category, $subcategory,$fabricant, $valeur);

    my $categories = $lp->loadCategories();
    open (FILE, "<$dir/dosearchanimal.html") or die "cannot open file $dir/dosearchanimal.html";
    my $menu = loadMenu();
    #my $cats = getCat();
    while (<FILE>) {	
	s/\$LABEL{'([\w]+)'}/ exists $SERVER{$1} ? $SERVER{$1} : $1 /eg; 
	s/\$LANG/$lang/g;
	s/\$ERROR{'([\w]+)'}//g;
	s/\$ARTICLE{'index_table'}/$string/g;
	#s/\$ARTICLE{'news'}//g;
	s/\$OPTIONS{'categories'}/$categories/g;
	s/\$SESSIONID/$session_id/g;
	s/\$ARTICLE{'main_menu'}/$menu/g;
	s/\$ARTICLE{'search'}/$string2/g;
	$content .= $_;	
    }
	$content = Compress::Zlib::memGzip($content)  if $can_do_gzip; ;
	print "Content-Length: ", length($content) , "\n";
	print "Content-Encoding: gzip\n" ;
	print "Content-Type: text/html\n\n"; 
	print $content;
        close (FILE);	
}

sub doSearchAnimal {
    my $category = $query->param('category');
    $category =~ s/\'/\'\'/g;
    my $subcategory = $query->param('subcategory');
    $subcategory =~ s/\'/\'\'/g;
    my $fabricant = $query->param('fabricant');
    $fabricant =~ s/\'/\'\'/g;
    my $valeur = $query->param('valeur');
    $valeur  =~ s/\'/\'\'/g;
    my $buy_price_min = $query->param ("price_min");
    $buy_price_min  =~ s/\'/\'\'/g;
    my $buy_price_max = $query->param("price_max");
    $buy_price_max =~ s/\'/\'\'/g;
    my $used = $query->param("used");
    my $string;    
    my $select = "DISTINCT article.nom";        
    my  $from = "article,";
    my  $where = "";
    if ($category) {
	$from .= "categorie_libelle_langue";
	$where .= "article.ref_categorie = categorie_libelle_langue.ref_categorie AND categorie_libelle_langue.ref_categorie = (SELECT libelle.libelle FROM categorie_libelle_langue, libelle, langue WHERE libelle.libelle = '$category' AND categorie_libelle_langue.ref_langue = langue.id_langue AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND langue.key = '$lang')";
	}

    if ($subcategory) {
	$from .= ",subcategorie_libelle_langue";
	$where .= " AND article.ref_subcategorie = subcategorie_libelle_langue.ref_subcategorie AND subcategorie_libelle_langue.ref_subcategorie = (SELECT libelle.libelle FROM subcategorie_libelle_langue, libelle, langue WHERE libelle.libelle = '$subcategory' AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND langue.key = '$lang')";
    }
    if ($fabricant) {if ($fabricant ne '---------') {$where .= " AND article.marque = '$fabricant'";}}
    if ($buy_price_min) {$where .= " AND article.prix >= '$buy_price_min'";}
    if ($buy_price_max) {$where .= " AND article.prix <= '$buy_price_max'";}
    if ($valeur) {$where .= " AND article.nom LIKE '%$valeur%'";}
    
     
    if ($used) {
	$from .= ",etat_libelle_langue";
	if ($where ne ''){
		$where .= " AND article.ref_etat = id_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}else {
		$where .= " article.ref_etat = id_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}
    }


    my  $total = '0';    
    my  ($d)= $db->sqlSelect("count(id_article)", $from, $where ." AND ref_statut = '3'");
    
    my  $nb_page = arrondi ($d / 40, 1);my  $min_index = '0';my  $max_index = '40';

    for (my  $i = '0'; $i < $nb_page;$i++) {
	my $n2 = $i %= 10;
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=dosearchanimal&amp;min_index=$min_index&amp;session=$session_id&category=$category&fabricant=$fabricant&price_min=$buy_price_min&price_max=$buy_price_max\"  class=\"menulink2\" ><-$i-></a>&#160;&nbsp;<img alt=\"\" alt=\"\" src=\"../images/next2.gif\" height=\"13px\" width=\"13px\">";		
	$min_index += 40;	
    }
    return $string;
}
#load search index result
sub doSearchAnimalIndexed {
    my $category = $query->param('category');
    $category =~ s/\'/\'\'/g;
    my $subcategory = $query->param('subcategory');
    $subcategory =~ s/\'/\'\'/g;
    my $fabricant = $query->param('fabricant');
    $fabricant =~ s/\'/\'\'/g;
    my $valeur = $query->param('valeur');
    $valeur  =~ s/\'/\'\'/g;
    my $buy_price_min = $query->param ("price_min");
    $buy_price_min  =~ s/\'/\'\'/g;
    my $buy_price_max = $query->param("price_max");
    $buy_price_max =~ s/\'/\'\'/g;
    my $used = $query->param("used");
    my $string;
    my $select = "DISTINCT article.nom,id_article, prix,pochette,marque";
    my  $from = "article";
    my  $where;

    if ($category) {
	$from .= ",categorie_libelle_langue";
	$where .= " article.ref_categorie = categorie_libelle_langue.ref_categorie AND categorie_libelle_langue.ref_categorie = (SELECT ref_categorie FROM categorie_libelle_langue, libelle, langue WHERE libelle.libelle = '$category' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}

    if ($subcategory) {
	$from .= ",subcategorie_libelle_langue";
	$where .= " AND article.ref_subcategorie = subcategorie_libelle_langue.ref_subcategorie AND subcategorie_libelle_langue.ref_subcategorie = (SELECT ref_subcategorie FROM subcategorie_libelle_langue, libelle, langue WHERE libelle.libelle = '$subcategory' AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}

    if ($fabricant) {if ($fabricant ne '---------') {$where .= " AND article.marque = '$fabricant'";}}
    if ($buy_price_min) {$where .= " AND article.prix >= '$buy_price_min'";	}
    if ($buy_price_max) {$where .= " AND article.prix <= '$buy_price_max'";	}
    if ($valeur) {$where .= " AND article.nom LIKE '%$valeur'";}
    
 
    if ($used) {
	$from .= ",etat_libelle_langue";
	if ($where ne ''){
		$where .= " AND article.ref_etat = id_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}else {
		$where .= " article.ref_etat = id_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}
	}

    
    my  $total = '0';  
    my  ($d)= $db->sqlSelectMany($select, $from, $where ." AND ref_statut = '3'");
    my  $index_start = $query->param ("min_index") ;$index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index") ; $index_end=~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d",$year+1900,$mon+1,$mday;    
    if (!$index_start ) {$index_start = 0;}if (!$index_end ) {$index_end = 40;}
    $string = "<table style=\"border-width:thin; border-style:dotted; border-top-color:#94CEFA;border-right-color:#94CEFA;border-left-color:#94CEFA; border-right-width:2px; border-bottom-color:#94CEFA\" width=\"555\" border=\"0\"><tr bgcolor=\"#DBE4F8\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"120\">$SERVER{'article_name_label'}</td><td align=\"left\" width=\"120\">$SERVER{'fabricant'}</td><td align=\"left\">$SERVER{'article_price_label'}</td><td align=\"left\"></td></tr>";
    my  ($c)= $db->sqlSelectMany($select, $from, $where ." LIMIT $index_start, $index_end");
    while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'price'},$ARTICLE{'image'},$ARTICLE{'fabricant'})=$c->fetchrow()) {
	$string .= "<tr><td align=\"left\"><img alt=\"\" alt=\"\" src=\"$ARTICLE{'image'}\"></td><td align=\"left\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'fabricant'}</td><td align=\"left\">$ARTICLE{'price'}</td><td align=\"left\">$ARTICLE{'depot'}</td></tr>";
    }
    $string .="</table>";    
    return $string;
}

sub doSearchWear {
    my $category = $query->param("category");
    $category  =~ s/[^\w ]//g;    
    my $subcategory = $query->param("subcategory");
    $subcategory  =~ s/[^\w ]//g;    
    my $fabricant = $query->param("fabricant");
    $fabricant =~ s/[^\w ]//g;    
    my $valeur = $query->param("valeur");
    $valeur =~ s/[^\w ]//g;
    my $buy_price_min = $query->param ("price_min");
    $buy_price_min =~ s/[^\w ]//g;    
    my $buy_price_max = $query->param("price_max");
    $buy_price_max =~ s/[^\w ]//g;
    my $used = $query->param("used");
    my $string;    
    my $select = "DISTINCT article.nom";        
    my  $from = "article, libelle, langue";
    my  $where = " id_article = id_article ";
    my $ref_cat;
    my $ref_subcat;
    my $add;
    if ($category) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $where .= " AND article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
	    $from .= ", categorie_libelle_langue ";
    }
    if ($subcategory) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcategory' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $where .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
    if ($fabricant) {if ($fabricant ne '---------') {$where .= " AND article.marque = '$fabricant'";}}
    if ($buy_price_min) {$where .= " AND article.prix >= '$buy_price_min'";}
    if ($buy_price_max) {$where .= " AND article.prix <= '$buy_price_max'";}
    if ($valeur) {$where .= " AND article.nom LIKE '%$valeur%'";}
      if ($used) {
	$from .= ",etat_libelle_langue";
	if ($where ne ''){
		$where .= " AND article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}else {
		$where .= " article.ref_etat = id_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}
    }

    my  $total = '0';    
    my  ($d)= $db->sqlSelect("count(id_article)", $from, $where ." AND ref_statut = '3'");
    
    my  $nb_page = arrondi ($d / 40, 1);my  $min_index = '0';my  $max_index = '40';

    for (my  $i = '0'; $i < $nb_page;$i++) {
	my $n2 = $i %= 10;
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=dosearchwear&amp;min_index=$min_index&amp;session=$session_id&category=$category&fabricant=$fabricant&price_min=$buy_price_min&price_max=$buy_price_max&subcategory=$subcategory\"  class=\"menulink2\" ><-$i-></a>&#160;&nbsp;<img alt=\"\" alt=\"\" src=\"../images/next2.gif\" height=\"13px\" width=\"13px\">";		
	$min_index += 40;	
    }
    return $string;
}

sub doSearchGames {
    my $category = $query->param("category");
    $category  =~ s/[^\w ]//g;    
    my $subcategory = $query->param("subcategory");
    $subcategory  =~ s/[^\w ]//g;    
    my $fabricant = $query->param("fabricant");
    $fabricant =~ s/[^\w ]//g;    
    my $valeur = $query->param("valeur");
    $valeur =~ s/[^\w ]//g;
    my $buy_price_min = $query->param ("price_min");
    $buy_price_min =~ s/[^\w ]//g;    
    my $buy_price_max = $query->param("price_max");
    $buy_price_max =~ s/[^\w ]//g;
    my $used = $query->param("used");
    my $string;    
    my $select = "DISTINCT article.nom";        
    my  $from = "article, libelle, langue";
    my  $where = " id_article = id_article ";
    my $ref_cat;
    my $ref_subcat;
    my $add;
    if ($category) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $where .= " AND article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
	    $from .= ", categorie_libelle_langue ";
    }
    if ($subcategory) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcategory' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $where .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
    if ($fabricant) {if ($fabricant ne '---------') {$where .= " AND article.marque = '$fabricant'";}}
    if ($buy_price_min) {$where .= " AND article.prix >= '$buy_price_min'";}
    if ($buy_price_max) {$where .= " AND article.prix <= '$buy_price_max'";}
    if ($valeur) {$where .= " AND article.nom LIKE '%$valeur%'";}
      if ($used) {
	$from .= ",etat_libelle_langue";
	if ($where ne ''){
		$where .= " AND article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}else {
		$where .= " article.ref_etat = id_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}
    }

    my  $total = '0';    
    my  ($d)= $db->sqlSelect("count(id_article)", $from, $where ." AND ref_statut = '3'");
    
    my  $nb_page = arrondi ($d / 40, 1);my  $min_index = '0';my  $max_index = '40';

    for (my  $i = '0'; $i < $nb_page;$i++) {
	my $n2 = $i %= 10;
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=dosearchwear&amp;min_index=$min_index&amp;session=$session_id&category=$category&fabricant=$fabricant&price_min=$buy_price_min&price_max=$buy_price_max&subcategory=$subcategory\"  class=\"menulink2\" ><-$i-></a>&#160;&nbsp;<img alt=\"\" alt=\"\" src=\"../images/next2.gif\" height=\"13px\" width=\"13px\">";		
	$min_index += 40;	
    }
    return $string;
}

sub doSearchGamesIndexed {
    my $category = $query->param("category");
    $category  =~ s/[^\w ]//g;    
    my $subcategory = $query->param("subcat");
    $subcategory  =~ s/[^\w ]//g;    
    my $fabricant = $query->param("fabricant");
    $fabricant =~ s/[^\w ]//g;    
    my $valeur = $query->param("valeur");
    $valeur =~ s/[^\w ]//g;
    my $buy_price_min = $query->param ("price_min");
    $buy_price_min =~ s/[^\w ]//g;    
    my $buy_price_max = $query->param("price_max");
    $buy_price_max =~ s/[^\w ]//g;
    my $taille = $query->param("taille");    
    my $used = $query->param("used");
    my $string;    
    my $select = "DISTINCT article.nom,id_article, prix,pochette,marque";
    my  $from = "article, libelle, langue";
    my  $where = "id_article = id_article ";
    my $ref_cat;
    my $ref_subcat;
    my $add;
    if ($category) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $where .= " AND article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
	    $from .= ", categorie_libelle_langue ";
    }
    if ($subcategory) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcategory' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $where .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
    
    if ($taille) {$where .= " AND article.taille = '$taille'";}
    
    if ($valeur) {$where .= " AND article.nom LIKE '%$valeur%'";}    
    
    if ($fabricant) {if ($fabricant ne '---------') {$where .= " AND article.marque = '$fabricant'";}}
    if ($buy_price_min) {$where .= " AND article.prix >= '$buy_price_min'";	}
    if ($buy_price_max) {$where .= " AND article.prix <= '$buy_price_max'";	}
    if ($valeur) {$where .= " AND article.nom LIKE '%$valeur%'";}
         if ($used) {
	$from .= ",etat_libelle_langue";
	if ($where ne ''){
		$where .= " AND article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}else {
		$where .= " article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}
    }
    my  $total = '0';  
    my  ($d)= $db->sqlSelectMany($select, $from, $where ." AND ref_statut = '3'");
    my  $index_start = $query->param ("min_index") ;$index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index") ; $index_end=~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d",$year+1900,$mon+1,$mday;    
    if (!$index_start ) {$index_start = 0;}if (!$index_end ) {$index_end = 40;}
    $string = "<table style=\"border-width:thin; border-style:dotted; border-top-color:#94CEFA;border-right-color:#94CEFA;border-left-color:#94CEFA; border-right-width:2px; border-bottom-color:#94CEFA\" width=\"555\" border=\"0\"><tr bgcolor=\"#DBE4F8\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"120\">$SERVER{'article_name_label'}</td><td align=\"left\" width=\"120\">$SERVER{'fabricant'}</td><td align=\"left\">$SERVER{'article_price_label'}</td><td align=\"left\"></td></tr>";
    my  ($c)= $db->sqlSelectMany($select, $from, $where ." LIMIT $index_start, $index_end");
    while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'price'},$ARTICLE{'image'},$ARTICLE{'fabricant'})=$c->fetchrow()) {
	$string .= "<tr><td align=\"left\"><img alt=\"\" alt=\"\" src=\"$ARTICLE{'image'}\"></td><td align=\"left\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'fabricant'}</td><td align=\"left\">$ARTICLE{'price'}</td><td align=\"left\">$ARTICLE{'depot'}</td></tr>";
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

#load search index result
sub doSearchWearIndexed {
    my $category = $query->param("category");
    $category  =~ s/[^\w ]//g;    
    my $subcategory = $query->param("subcategory");
    $subcategory  =~ s/[^\w ]//g;    
    my $fabricant = $query->param("fabricant");
    $fabricant =~ s/[^\w ]//g;    
    my $valeur = $query->param("valeur");
    $valeur =~ s/[^\w ]//g;
    my $buy_price_min = $query->param ("price_min");
    $buy_price_min =~ s/[^\w ]//g;    
    my $buy_price_max = $query->param("price_max");
    $buy_price_max =~ s/[^\w ]//g;
    my $taille = $query->param("taille");
    
    my $used = $query->param("used");
    my $string;    
    my $select = "DISTINCT article.nom,id_article, prix,pochette,marque";
    my  $from = "article, libelle, langue";
    my  $where = "id_article = id_article ";
    my $ref_cat;
    my $ref_subcat;
    my $add;
    if ($category) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $where .= " AND article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
	    $from .= ", categorie_libelle_langue ";
    }
    if ($subcategory) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcategory' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $where .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
    
    if ($taille) {$where .= " AND article.taille = '$taille'";}
    
    if ($valeur) {$where .= " AND article.nom LIKE '%$valeur%'";}    
    
    if ($fabricant) {if ($fabricant ne '---------') {$where .= " AND article.marque = '$fabricant'";}}
    if ($buy_price_min) {$where .= " AND article.prix >= '$buy_price_min'";	}
    if ($buy_price_max) {$where .= " AND article.prix <= '$buy_price_max'";	}
    if ($valeur) {$where .= " AND article.nom LIKE '%$valeur%'";}
         if ($used) {
	$from .= ",etat_libelle_langue";
	if ($where ne ''){
		$where .= " AND article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}else {
		$where .= " article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}
    }
    my  $total = '0';  
    my  ($d)= $db->sqlSelectMany($select, $from, $where ." AND ref_statut = '3'");
    my  $index_start = $query->param ("min_index") ;$index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index") ; $index_end=~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d",$year+1900,$mon+1,$mday;    
    if (!$index_start ) {$index_start = 0;}if (!$index_end ) {$index_end = 40;}
    $string = "<table style=\"border-width:thin; border-style:dotted; border-top-color:#94CEFA;border-right-color:#94CEFA;border-left-color:#94CEFA; border-right-width:2px; border-bottom-color:#94CEFA\" width=\"555\" border=\"0\"><tr bgcolor=\"#DBE4F8\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"120\">$SERVER{'article_name_label'}</td><td align=\"left\" width=\"120\">$SERVER{'fabricant'}</td><td align=\"left\">$SERVER{'article_price_label'}</td><td align=\"left\"></td></tr>";
    my  ($c)= $db->sqlSelectMany($select, $from, $where ." LIMIT $index_start, $index_end");
    while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'price'},$ARTICLE{'image'},$ARTICLE{'fabricant'})=$c->fetchrow()) {
	$string .= "<tr><td align=\"left\"><img alt=\"\" alt=\"\" src=\"$ARTICLE{'image'}\"></td><td align=\"left\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'fabricant'}</td><td align=\"left\">$ARTICLE{'price'}</td><td align=\"left\">$ARTICLE{'depot'}</td></tr>";
    }
    $string .="</table>";    
    return $string;
}

sub doSearchLingerie {
    my $category = $query->param("category");
    $category  =~ s/[^\w ]//g;    
    my $subcategory = $query->param("subcategory");
    $subcategory  =~ s/[^\w ]//g;    
    my $fabricant = $query->param("fabricant");
    $fabricant =~ s/[^\w ]//g;    
    my $valeur = $query->param("valeur");
    $valeur =~ s/[^\w ]//g;
    my $buy_price_min = $query->param ("price_min");
    $buy_price_min =~ s/[^\w ]//g;    
    my $buy_price_max = $query->param("price_max");
    $buy_price_max =~ s/[^\w ]//g;
    my $used = $query->param("used");
    my $string;    
    my $select = "DISTINCT article.nom";        
    my  $from = "article, libelle, langue";
    my  $where = " id_article = id_article ";
    my $ref_cat;
    my $ref_subcat;
    my $add;

    if ($category) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $where .= " AND article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
	    $from .= ", categorie_libelle_langue ";
    }
    if ($subcategory) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcategory' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $where .= " AND subcategorie_libelle_langue.ref_subcategorie = '$ref_subcat' AND  article.ref_subcategorie = '$ref_subcat'";
	    $from .= ", subcategorie_libelle_langue";
    }
 
    if ($fabricant) {if ($fabricant ne '---------') {$where .= " AND article.marque = '$fabricant'";}}
    if ($buy_price_min) {$where .= " AND article.prix >= '$buy_price_min'";}
    if ($buy_price_max) {$where .= " AND article.prix <= '$buy_price_max'";}
    if ($valeur) {$where .= " AND article.nom LIKE '%$valeur%'";}
      if ($used) {
	$from .= ",etat_libelle_langue";
	if ($where ne ''){
		$where .= " AND article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}else {
		$where .= " article.ref_etat = id_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}
    }

    my  $total = '0';    
    my  ($d)= $db->sqlSelect("count(id_article)", $from, $where ." AND ref_statut = '3'");
    
    my  $nb_page = arrondi ($d / 40, 1);my  $min_index = '0';my  $max_index = '40';

    for (my  $i = '0'; $i < $nb_page;$i++) {
	my $n2 = $i %= 10;
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=dosearchwear&amp;min_index=$min_index&amp;session=$session_id&category=$category&fabricant=$fabricant&price_min=$buy_price_min&price_max=$buy_price_max&subcategory=$subcategory\"  class=\"menulink2\" ><-$i-></a>&#160;&nbsp;<img alt=\"\" alt=\"\" src=\"../images/next2.gif\" height=\"13px\" width=\"13px\">";		
	$min_index += 40;	
    }
    return $string;

}
#load search index result
sub doSearchLingerieIndexed {
    my $category = $query->param("category");
    $category  =~ s/[^\w ]//g;    
    my $subcategory = $query->param("subcategory");
    $subcategory  =~ s/[^\w ]//g;    
    my $fabricant = $query->param("fabricant");
    $fabricant =~ s/[^\w ]//g;    
    my $valeur = $query->param("valeur");
    $valeur =~ s/[^\w ]//g;
    my $buy_price_min = $query->param ("price_min");
    $buy_price_min =~ s/[^\w ]//g;    
    my $buy_price_max = $query->param("price_max");
    $buy_price_max =~ s/[^\w ]//g;
    my $taille = $query->param("taille");
    
    my $used = $query->param("used");
    my $string;    
    my $select = "DISTINCT article.nom,id_article, prix,pochette,marque";
    my  $from = "article, libelle, langue";
    my  $where = "id_article = id_article ";
    my $ref_cat;
    my $ref_subcat;
    my $add;
    if ($category) {
            my  @cat = $db->sqlSelect("ref_categorie","categorie_libelle_langue, libelle, langue","libelle.libelle = '$category' and  categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_cat = $cat[0];
	    $where .= " AND article.ref_categorie = $ref_cat AND categorie_libelle_langue.ref_categorie = $ref_cat and  article.ref_categorie = $ref_cat";
	    $from .= ", categorie_libelle_langue ";
    }
    if ($subcategory) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcategory' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $where .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
    
    if ($taille) {$where .= " AND article.taille = '$taille'";}
    
    if ($valeur) {$where .= " AND article.nom LIKE '%$valeur%'";}    
    
    if ($fabricant) {if ($fabricant ne '---------') {$where .= " AND article.marque = '$fabricant'";}}
    if ($buy_price_min) {$where .= " AND article.prix >= '$buy_price_min'";	}
    if ($buy_price_max) {$where .= " AND article.prix <= '$buy_price_max'";	}
    if ($valeur) {$where .= " AND article.nom LIKE '%$valeur%'";}
         if ($used) {
	$from .= ",etat_libelle_langue";
	if ($where ne ''){
		$where .= " AND article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}else {
		$where .= " article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}
    }
    my  $total = '0';  
    my  ($d)= $db->sqlSelectMany($select, $from, $where ." AND ref_statut = '3'");
    my  $index_start = $query->param ("min_index") ;$index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index") ; $index_end=~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d",$year+1900,$mon+1,$mday;    
    if (!$index_start ) {$index_start = 0;}if (!$index_end ) {$index_end = 40;}
    $string = "<table style=\"border-width:thin; border-style:dotted; border-top-color:#94CEFA;border-right-color:#94CEFA;border-left-color:#94CEFA; border-right-width:2px; border-bottom-color:#94CEFA\" width=\"555\" border=\"0\"><tr bgcolor=\"#DBE4F8\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"120\">$SERVER{'article_name_label'}</td><td align=\"left\" width=\"120\">$SERVER{'fabricant'}</td><td align=\"left\">$SERVER{'article_price_label'}</td><td align=\"left\"></td></tr>";
    my  ($c)= $db->sqlSelectMany($select, $from, $where ." LIMIT $index_start, $index_end");
    while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'price'},$ARTICLE{'image'},$ARTICLE{'fabricant'})=$c->fetchrow()) {
	$string .= "<tr><td align=\"left\"><img alt=\"\" alt=\"\" src=\"$ARTICLE{'image'}\"></td><td align=\"left\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'fabricant'}</td><td align=\"left\">$ARTICLE{'price'}</td><td align=\"left\">$ARTICLE{'depot'}</td></tr>";
    }
    $string .="</table>";    
    return $string;
}


sub doSearchDvd {
    my $subcategory = $query->param("subcategory");
    my $fabricant = $query->param("fabricant");
    my $actor = $query->param("actor");
    my $realisator = $query->param("realisator");
    my $annee = $query->param("year");
    my $buy_price_min = $query->param ("price_min");
    my $buy_price_max = $query->param("price_max");
    my $used = $query->param("used");
    my $string;    
    my $select = "DISTINCT article.nom";        
    my  $from = "article, libelle, langue";
    my  $where = " id_article = id_article ";
    my $ref_cat;
    my $ref_subcat;
    my $add;
    if ($subcategory) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcategory' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $where .= " AND subcategorie_libelle_langue.ref_subcategorie = '$ref_subcat' AND  article.ref_subcategorie = '$ref_subcat'";
	    $from .= ", subcategorie_libelle_langue";
    }
 
    if ($buy_price_min) {$where .= " AND article.prix >= '$buy_price_min'";	}
    if ($buy_price_max) {$where .= " AND article.prix <= '$buy_price_max'";	}
    if ($actor and $actor ne 'undefined') {$where .= " AND article.acteurs LIKE '%$actor%'";}
    if ($realisator and $realisator ne 'undefined') {$where .= " AND article.realisateur LIKE '%$realisator%'";}
    if ($annee and $annee ne 'undefined') {$where .= " AND article.annee LIKE '%$annee%'";}
      if ($used) {
	$from .= ",etat_libelle_langue";
	if ($where ne ''){
		$where .= " AND article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}else {
		$where .= " article.ref_etat = id_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}
    }

    my  $total = '0';    
    my  ($d)= $db->sqlSelect("count(id_article)", $from, $where ." AND ref_statut = '3'");
    
    my  $nb_page = arrondi ($d / 40, 1);my  $min_index = '0';my  $max_index = '40';

    for (my  $i = '0'; $i < $nb_page;$i++) {
	my $n2 = $i %= 10;
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=dosearchwear&amp;min_index=$min_index&amp;session=$session_id&category=$subcategory&fabricant=$fabricant&price_min=$buy_price_min&price_max=$buy_price_max\"  class=\"menulink2\" ><-$i-></a>&#160;&nbsp;<img alt=\"\" alt=\"\" src=\"../images/next2.gif\" height=\"13px\" width=\"13px\">";		
	$min_index += 40;	
    }
    return $string;

}


sub doSearchBook {
    my $subcategory = $query->param("subcategory");
    my $fabricant = $query->param("fabricant");
    my $titre = $query->param("title");
    my $auteur = $query->param("author");
    my $editeur = $query->param("editor");
    my $annee = $query->param("year");
    my $buy_price_min = $query->param ("price_min");
    my $buy_price_max = $query->param("price_max");
    my $used = $query->param("used");
    my $string;    
    my $select = "DISTINCT article.nom";        
    my  $from = "article, libelle, langue";
    my  $where = " id_article = id_article ";
    my $ref_cat;
    my $ref_subcat;
    my $add;
    if ($subcategory) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcategory' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $where .= " AND subcategorie_libelle_langue.ref_subcategorie = '$ref_subcat' AND  article.ref_subcategorie = '$ref_subcat'";
	    $from .= ", subcategorie_libelle_langue";
    }
 
    if ($fabricant) {if ($fabricant ne '---------') {$where .= " AND article.marque = '$fabricant'";}}
    if ($buy_price_min) {$where .= " AND article.prix >= '$buy_price_min'";}
    if ($buy_price_max) {$where .= " AND article.prix <= '$buy_price_max'";}
    if ($editeur) {$where .= " AND article.marque LIKE '%$editeur%'";}
    if ($titre) {$where .= " AND article.nom LIKE '%$titre%'";}
    if ($annee) {$where .= " AND article.annee LIKE '%$annee%'";}
    if ($auteur) {$where .= " AND article.auteur LIKE '%$auteur%'";}
      if ($used) {
	$from .= ",etat_libelle_langue";
	if ($where ne ''){
		$where .= " AND article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}else {
		$where .= " article.ref_etat = id_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}
    }

    my  $total = '0';    
    my  ($d)= $db->sqlSelect("count(id_article)", $from, $where ." AND ref_statut = '3'");
    
    my  $nb_page = arrondi ($d / 40, 1);my  $min_index = '0';my  $max_index = '40';

    for (my  $i = '0'; $i < $nb_page;$i++) {
	my $n2 = $i %= 10;
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=dosearchwear&amp;min_index=$min_index&amp;session=$session_id&category=$subcategory&fabricant=$fabricant&price_min=$buy_price_min&price_max=$buy_price_max\"  class=\"menulink2\" ><-$i-></a>&#160;&nbsp;<img alt=\"\" alt=\"\" src=\"../images/next2.gif\" height=\"13px\" width=\"13px\">";		
	$min_index += 40;	
    }
    return $string;

}
#load search index result
sub doSearchBookIndexed {
    my $subcategory = $query->param("category");
    my $fabricant = $query->param("fabricant");
    my $titre = $query->param("title");
    my $auteur = $query->param("author");
    my $editeur = $query->param("editor");
    my $annee = $query->param("year");
    my $buy_price_min = $query->param ("price_min");
    $buy_price_min =~ s/[^\w ]//g;    
    my $buy_price_max = $query->param("price_max");
    $buy_price_max =~ s/[^\w ]//g;
    my $taille = $query->param("taille");
    
    my $used = $query->param("used");
    my $string;    
    my $select = "DISTINCT article.nom,id_article, prix,pochette,marque";
    my  $from = "article, libelle, langue";
    my  $where = "id_article = id_article ";
    my $ref_cat;
    my $ref_subcat;
    my $add;
    if ($subcategory) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcategory' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $where .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
    
    if ($taille) {$where .= " AND article.taille = '$taille'";}
    if ($fabricant) {if ($fabricant ne '---------') {$where .= " AND article.marque = '$fabricant'";}}
    if ($buy_price_min) {$where .= " AND article.prix >= '$buy_price_min'";	}
    if ($buy_price_max) {$where .= " AND article.prix <= '$buy_price_max'";	}
    if ($editeur) {$where .= " AND article.marque LIKE '%$editeur%'";}
    if ($titre) {$where .= " AND article.nom LIKE '%$titre%'";}
    if ($annee) {$where .= " AND article.annee LIKE '%$annee%'";}
    if ($auteur) {$where .= " AND article.auteur LIKE '%$auteur%'";}
    
         if ($used) {
	$from .= ",etat_libelle_langue";
	if ($where ne ''){
		$where .= " AND article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}else {
		$where .= " article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}
    }
    my  $total = '0';  
    my  ($d)= $db->sqlSelectMany($select, $from, $where ." AND ref_statut = '3'");
    my  $index_start = $query->param ("min_index") ;$index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index") ; $index_end=~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d",$year+1900,$mon+1,$mday;    
    if (!$index_start ) {$index_start = 0;}if (!$index_end ) {$index_end = 40;}
    $string = "<table style=\"border-width:thin; border-style:dotted; border-top-color:#94CEFA;border-right-color:#94CEFA;border-left-color:#94CEFA; border-right-width:2px; border-bottom-color:#94CEFA\" width=\"555\" border=\"0\"><tr bgcolor=\"#DBE4F8\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"120\">$SERVER{'article_name_label'}</td><td align=\"left\" width=\"120\">$SERVER{'fabricant'}</td><td align=\"left\">$SERVER{'article_price_label'}</td><td align=\"left\"></td></tr>";
    my  ($c)= $db->sqlSelectMany($select, $from, $where ." LIMIT $index_start, $index_end");
    while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'price'},$ARTICLE{'image'},$ARTICLE{'fabricant'})=$c->fetchrow()) {
	$string .= "<tr><td align=\"left\"><img alt=\"\" alt=\"\" src=\"$ARTICLE{'image'}\"></td><td align=\"left\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'fabricant'}</td><td align=\"left\">$ARTICLE{'price'}</td><td align=\"left\">$ARTICLE{'depot'}</td></tr>";
    }
    $string .="</table>";    
    return $string;
}

sub doSearchDvdIndexed {
    my $subcategory = $query->param("subcategory");
    my $fabricant = $query->param("fabricant");
    my $actor = $query->param("actor");
    my $realisator = $query->param("realisator");
    my $annee = $query->param("year");
    my $buy_price_min = $query->param ("price_min");
    $buy_price_min =~ s/[^\w ]//g;    
    my $buy_price_max = $query->param("price_max");
    $buy_price_max =~ s/[^\w ]//g;
    my $taille = $query->param("taille");
    
    my $used = $query->param("used");
    my $string;    
    my $select = "DISTINCT article.nom,id_article, prix,pochette,marque";
    my  $from = "article, libelle, langue";
    my  $where = "id_article = id_article ";
    my $ref_cat;
    my $ref_subcat;
    my $add;
    if ($subcategory) {
            my  @sub_cat = $db->sqlSelect("ref_subcategorie","subcategorie_libelle_langue, libelle, langue","libelle.libelle = '$subcategory' and  subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_subcat = $sub_cat[0];
	    $where .= " AND subcategorie_libelle_langue.ref_subcategorie = $ref_subcat AND  article.ref_subcategorie = $ref_subcat";
	    $from .= ", subcategorie_libelle_langue";
    }
    
    if ($taille) {$where .= " AND article.taille = '$taille'";}
    if ($fabricant) {if ($fabricant ne '---------') {$where .= " AND article.marque = '$fabricant'";}}
    if ($buy_price_min) {$where .= " AND article.prix >= '$buy_price_min'";	}
    if ($buy_price_max) {$where .= " AND article.prix <= '$buy_price_max'";	}
    if ($actor and $actor ne 'undefined') {$where .= " AND article.acteurs LIKE '%$actor%'";}
    if ($realisator and $realisator ne 'undefined') {$where .= " AND article.realisateur LIKE '%$realisator%'";}
    if ($annee and $annee ne 'undefined') {$where .= " AND article.annee LIKE '%$annee%'";}
    
    
         if ($used) {
	$from .= ",etat_libelle_langue";
	if ($where ne ''){
		$where .= " AND article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}else {
		$where .= " article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}
    }
    my  $total = '0';  
    my  ($d)= $db->sqlSelectMany($select, $from, $where ." AND ref_statut = '3'");
    my  $index_start = $query->param ("min_index") ;$index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index") ; $index_end=~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d",$year+1900,$mon+1,$mday;    
    if (!$index_start ) {$index_start = 0;}if (!$index_end ) {$index_end = 40;}
    $string = "<table style=\"border-width:thin; border-style:dotted; border-top-color:#94CEFA;border-right-color:#94CEFA;border-left-color:#94CEFA; border-right-width:2px; border-bottom-color:#94CEFA\" width=\"555\" border=\"0\"><tr bgcolor=\"#DBE4F8\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"120\">$SERVER{'article_name_label'}</td><td align=\"left\" width=\"120\">$SERVER{'fabricant'}</td><td align=\"left\">$SERVER{'article_price_label'}</td><td align=\"left\"></td></tr>";
    my  ($c)= $db->sqlSelectMany($select, $from, $where ." LIMIT $index_start, $index_end");
    while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'price'},$ARTICLE{'image'},$ARTICLE{'fabricant'})=$c->fetchrow()) {
	$string .= "<tr><td align=\"left\"><img alt=\"\" alt=\"\" src=\"$ARTICLE{'image'}\"></td><td align=\"left\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'fabricant'}</td><td align=\"left\">$ARTICLE{'price'}</td><td align=\"left\">$ARTICLE{'depot'}</td></tr>";
    }
    $string .="</table>";    
    return $string;
}

sub doSearchWine {
    my $country = $query->param("country");
    my $cepage = $query->param("cepage");
    my $type = $query->param("type");
    my $valeur = $query->param("valeur");
    $valeur =~ s/[^\w ]//g;
    my $buy_price_min = $query->param ("price_min");
    $buy_price_min =~ s/[^\w ]//g;    
    my $buy_price_max = $query->param("price_max");
    $buy_price_max =~ s/[^\w ]//g;
    my $used = $query->param("used");
    my $string;    
    my $select = "DISTINCT article.nom";        
    my  $from = "article";
    my  $where = " id_article = id_article ";
    my $ref_cat;
    my $ref_subcat;
    my $add;
    my $ref_wine_type;
    if ($country) {
	    my  @cat = $db->sqlSelect("id_pays_region_vin","pays_region_vin", "nom = '$country'");
	    $ref_cat = $cat[0];
	    $where .= " AND article.ref_pays_region_vin = $ref_cat";
    }
    if ($cepage) {
            my  @sub_cat = $db->sqlSelect("id_cepage","cepage","nom = '$cepage'");
	    $ref_subcat = $sub_cat[0];
	    $where .= " AND article.ref_cepage = $ref_subcat";
    }
	                                                                    ##
    if ($type) {
	    my @sub_wine_type = $db->sqlSelect("ref_type_de_vin","type_de_vin_libelle_langue,libelle,langue","libelle.libelle = '$type' and type_de_vin_libelle_langue.ref_libelle = libelle.id_libelle and type_de_vin_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_wine_type = $sub_wine_type[0];
	    $where .=  " AND article.ref_type_de_vin = $ref_wine_type";
    }
    if ($where ne "") {
	$where .= " AND article.ref_categorie = 27";
    }	
    
    
    if ($buy_price_min) {$where .= " AND article.prix >= '$buy_price_min'";}
    if ($buy_price_max) {$where .= " AND article.prix <= '$buy_price_max'";}
    if ($valeur) {$where .= " AND article.nom LIKE '%$valeur%'";}
    

    my  $total = '0';    
    my  ($d)= $db->sqlSelect("count(id_article)", $from, $where ." AND ref_statut = '3'");
    
    my  $nb_page = arrondi ($d / 40, 1);my  $min_index = '0';my  $max_index = '40';

    for (my  $i = '0'; $i < $nb_page;$i++) {
	my $n2 = $i %= 10;
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=dosearchwine&amp;min_index=$min_index&price_min=$buy_price_min&price_max=$buy_price_max&cepage=$cepage&type=$type&country=$country\"  class=\"menulink2\" ><-$i-></a>&#160;&nbsp;<img alt=\"\" alt=\"\" src=\"../images/next2.gif\" height=\"13px\" width=\"13px\">";		
	$min_index += 40;	
    }
    return $string;

}
#load search index result
sub doSearchWineIndexed {
    my $country = $query->param("country");
    my $cepage = $query->param("cepage");
    my $type = $query->param("type");
    my $valeur = $query->param("valeur");
    $valeur =~ s/[^\w ]//g;
    my $buy_price_min = $query->param ("price_min");
    $buy_price_min =~ s/[^\w ]//g;    
    my $buy_price_max = $query->param("price_max");
    $buy_price_max =~ s/[^\w ]//g;
    my $taille = $query->param("taille");
    my $fabricant = $query->param("fabricant");
    my $used = $query->param("used");
    my $string;    
    my $select = "DISTINCT article.nom,id_article, prix,pochette,marque";
    my  $from = "article, libelle, langue";
    my  $where = "id_article = id_article ";
    my $ref_cat;
    my $ref_subcat;
    my $ref_wine_type;
    my $add;
    if ($country) {
            my  @cat = $db->sqlSelect("id_pays_region_vin","pays_region_vin", "nom = '$country'");
	    $ref_cat = $cat[0];
	    $where .= " AND article.ref_pays_region_vin = $ref_cat";
    }
    if ($cepage) {
            my  @sub_cat = $db->sqlSelect("id_cepage","cepage","nom = '$cepage'");
	    $ref_subcat = $sub_cat[0];
	    $where .= " AND article.ref_cepage = $ref_subcat";
    }
	
    if ($type) {
	    my @sub_wine_type = $db->sqlSelect("ref_type_de_vin","type_de_vin_libelle_langue,libelle,langue","libelle.libelle = '$type' and type_de_vin_libelle_langue.ref_libelle = libelle.id_libelle and type_de_vin_libelle_langue.ref_langue = langue.id_langue and langue.key = '$lang'");
	    $ref_wine_type = $sub_wine_type[0];
	    $where .=  " AND article.ref_type_de_vin = $ref_wine_type";
    }
    if ($fabricant) {
	    $where .=  " AND article.marque = '$fabricant'";
    }
    
    if ($where ne "") {
	$where .= " AND article.ref_categorie = 27";
    }	
       if ($buy_price_min) {$where .= " AND article.prix >= '$buy_price_min'";	}
    if ($buy_price_max) {$where .= " AND article.prix <= '$buy_price_max'";	}
    if ($valeur) {$where .= " AND article.nom LIKE '%$valeur%'";}
         if ($used) {
	$from .= ",etat_libelle_langue";
	if ($where ne ''){
		$where .= " AND article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}else {
		$where .= " article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}
    }
    my  $total = '0';  
    
    my  $index_start = $query->param ("min_index") ;$index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index") ; $index_end=~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d",$year+1900,$mon+1,$mday;    
    if (!$index_start ) {$index_start = 0;}if (!$index_end ) {$index_end = 40;}
    $string = "<table style=\"border-width:thin; border-style:dotted; border-top-color:#94CEFA;border-right-color:#94CEFA;border-left-color:#94CEFA; border-right-width:2px; border-bottom-color:#94CEFA\" width=\"555\" border=\"0\"><tr bgcolor=\"#DBE4F8\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"120\">$SERVER{'article_name_label'}</td><td align=\"left\" width=\"120\">$SERVER{'fabricant'}</td><td align=\"left\">$SERVER{'article_price_label'}</td><td align=\"left\"></td></tr>";
    my  ($c)= $db->sqlSelectMany($select, $from, $where ." LIMIT $index_start, $index_end");
    while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'price'},$ARTICLE{'image'},$ARTICLE{'fabricant'})=$c->fetchrow()) {
	$string .= "<tr><td align=\"left\"><img alt=\"\" alt=\"\" src=\"$ARTICLE{'image'}\"></td><td align=\"left\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'fabricant'}</td><td align=\"left\">$ARTICLE{'price'}</td><td align=\"left\">$ARTICLE{'depot'}</td></tr>";
    }
    $string .="</table>";    
    return $string;
}

sub searchGames {
    my  $category = $query->param ('category');
    $category  =~ s/[^\w ]//g;
    my  $subcategory = $query->param('subcat');
    $subcategory  =~ s/[^\w ]//g;
    my $fabricant = $query->param ('fabricant');
    $fabricant  =~ s/[^\w ]//g;
    my $valeur = $query->param ('valeur');
    $valeur  =~ s/[^\w ]//g;

    my $content;
    $session = new CGI::Session("driver:File", $session_id, {Directory=>"$session_dir"});
    my $level = $session->param("level");
	if ($level eq '2') {
	    $LINK{'admin'} = "<a href=\"javascript:void(0)\" class=\"menulink\"  onclick=\"window.open('/cgi-bin/recordz.cgi?lang=$lang&amp;page=cms_manage_article&amp;session=$session_id;','MyWindow','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=no,width=800,height=600,left=20,top=20')\">Admin</a>";
	}
	else {
	    $LINK{'admin'} = "";
	}
    
    my $categories = $lp->loadCategories();
    my  $string = doSearchGames ($category, $subcategory,$fabricant, $valeur);
    my  $string2 = doSearchGamesIndexed ($category, $subcategory,$fabricant, $valeur);
    open (FILE, "<$dir/dosearchtv.html") or die "cannot open file $dir/dosearchtv.html";
    my $menu = loadMenu();
    while (<FILE>) {	
	s/\$LABEL{'([\w]+)'}/ exists $SERVER{$1} ? $SERVER{$1} : $1 /eg; 
	s/\$LANG/$lang/g;
	s/\$ERROR{'([\w]+)'}//g;
	s/\$ARTICLE{'index_table'}/$string/g;
	s/\$LINK{'admin'}/$LINK{'admin'}/g;
	s/\$SESSIONID/$session_id/g;
	s/\$OPTIONS{'categories'}/$categories/g;
	s/\$ARTICLE{'main_menu'}/$menu/g;
	s/\$ARTICLE{'search'}/$string2/g;
	$content .= $_;	
    }
	$content = Compress::Zlib::memGzip($content)  if $can_do_gzip; ;
	print "Content-Length: ", length($content) , "\n";
	print "Content-Encoding: gzip\n" ;
	print "Content-Type: text/html\n\n"; 
	print $content;
        close (FILE);	

}
sub searchTv {
    my  $category = $query->param ('category');
    $category  =~ s/[^\w ]//g;
    my  $subcategory = $query->param('subcategory');
    $subcategory  =~ s/[^\w ]//g;
    my $fabricant = $query->param ('fabricant');
    $fabricant  =~ s/[^\w ]//g;
    my $valeur = $query->param ('valeur');
    $valeur  =~ s/[^\w ]//g;

    my $content;
    $session = new CGI::Session("driver:File", $session_id, {Directory=>"$session_dir"});
    my $level = $session->param("level");
	if ($level eq '2') {
	    $LINK{'admin'} = "<a href=\"javascript:void(0)\" class=\"menulink\"  onclick=\"window.open('/cgi-bin/recordz.cgi?lang=$lang&amp;page=cms_manage_article&amp;session=$session_id;','MyWindow','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=no,width=800,height=600,left=20,top=20')\">Admin</a>";
	}
	else {
	    $LINK{'admin'} = "";
	}
    
    my $categories = $lp->loadCategories();
    my  $string = doSearchTv ($category, $subcategory,$fabricant, $valeur);
    my  $string2 = doSearchTvIndexed ($category, $subcategory,$fabricant, $valeur);
    open (FILE, "<$dir/dosearchtv.html") or die "cannot open file $dir/dosearchtv.html";
    my $menu = loadMenu();
    while (<FILE>) {	
	s/\$LABEL{'([\w]+)'}/ exists $SERVER{$1} ? $SERVER{$1} : $1 /eg; 
	s/\$LANG/$lang/g;
	s/\$ERROR{'([\w]+)'}//g;
	s/\$ARTICLE{'index_table'}/$string/g;
	s/\$LINK{'admin'}/$LINK{'admin'}/g;
	s/\$OPTIONS{'categories'}/$categories/g;
	s/\$SESSIONID/$session_id/g;
	s/\$ARTICLE{'main_menu'}/$menu/g;
	s/\$ARTICLE{'search'}/$string2/g;
	$content .= $_;	
    }
	$content = Compress::Zlib::memGzip($content)  if $can_do_gzip; ;
	print "Content-Length: ", length($content) , "\n";
	print "Content-Encoding: gzip\n" ;
	print "Content-Type: text/html\n\n"; 
	print $content;
        close (FILE);	
}


sub doSearchInfo {
    my $category = $query->param("category");    
    $category =~ s/[^\w ]//g;
    my  $subcategory = $query->param('subcat');
    $subcategory  =~ s/[^\w ]//g;    
    my $type_ecran = $query->param("type_ecran");
    $type_ecran =~ s/[^\w ]//g;
    my $fabricant = $query->param("fabricant");
    $fabricant =~ s/[^\w ]//g;
    my $tv_size_min = $query->param("tv_size_min");
    $tv_size_min =~ s/[^\w ]//g;
    my $tv_size_max = $query->param ("tv_size_max");
    $tv_size_max =~ s/[^\w ]//g;
    my $processor_min = $query->param("processor_min");
    $processor_min =~ s/[^\w ]//g;
    my $hard_drive_min = $query->param("hard_drive_min");
    $hard_drive_min =~ s/[^\w ]//g;
    my $hard_drive_max = $query->param("hard_drive_max");
    $hard_drive_max =~ s/[^\w ]//g;
    my $processor_max = $query->param("processor_max");
    $processor_max =~ s/[^\w ]//g;    
    my $ram_min = $query->param("ram_min");
    $ram_min =~ s/[^\w ]//g;
    my $ram_max = $query->param("ram_max");
    $ram_max =~ s/[^\w ]//g;
    my $buy_price_min = $query->param ("price_min");
    $buy_price_min =~ s/[^\w ]//g;
    my $buy_price_max = $query->param("price_max");
    $buy_price_max =~ s/[^\w ]//g;    
    my $ecran_dimension_min = $query->param("ecran_dimension_min");
    $ecran_dimension_min =~ s/[^\w ]//g;    
    my $ecran_dimension_max = $query->param("ecran_dimension_max");
    $ecran_dimension_max =~ s/[^\w ]//g;
    my $valeur = $query->param("valeur");
    $valeur =~ s/[^\w ]//g;
    my $used = $query->param("used");
    my $string;    
    my $select = "DISTINCT article.nom";        
    my  $from = "article";
    my  $where;
    if ($category) {
	$from .= ", categorie_libelle_langue";
	$where .= "article.ref_categorie = categorie_libelle_langue.ref_categorie_libelle_langue AND categorie_libelle_langue.ref_categorie = (SELECT ref_categorie FROM categorie_libelle_langue, libelle, langue WHERE libelle.libelle = '$category' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
    }
    if ($subcategory) {
	$from .= ", subcategorie_libelle_langue";
	$where .= "article.ref_subcategorie = subcategorie_libelle_langue.ref_subcategorie AND subcategorie_libelle_langue.ref_subcategorie = (SELECT ref_subcategory FROM subcategorie_libelle_langue, libelle, langue WHERE libelle.libelle = '$subcategory' AND subcategorie_libelle_langue.ref_libelle = libelle.ref_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
    }
    if ($type_ecran) {if ($type_ecran ne '---------') {
	$from .= ",type_ecran_libelle_langue";
	$where .= " AND article.ref_type_ecran  = type_ecran_libelle_langue.ref_type_ecran AND type_ecran_libelle_langue.ref_type_ecran = (SELECT libelle.libelle FROM type_ecran_libelle_langue, libelle, langue WHERE libelle.libelle = '$type_ecran' AND type_ecran_libelle_langue.ref_libelle = libelle.id_libelle AND type_ecran_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";}}
    if ($fabricant) {if ($fabricant ne '---------') {$where .= " AND article.marque = '$fabricant'";}}
    if ($tv_size_min) {$where .= " AND article.dimension >=  '$tv_size_min'";}
    if ($tv_size_max) {$where .= " AND article.dimension <=  '$tv_size_max'";}
    if ($ecran_dimension_min) {$where .= " AND article.dimension >=  '$ecran_dimension_min'";}
    if ($ecran_dimension_max) {$where .= " AND article.dimension <=  '$ecran_dimension_max'";}
    if ($buy_price_min) {$where .= " AND article.prix >= '$buy_price_min'";}
    if ($buy_price_max) {$where .= " AND article.prix <= '$buy_price_max'";	}
    if ($processor_min) {if ($where ne '') {$where .= " AND article.processeur  >= '$processor_min'";} else {$where .= " AND article.processeur  >= '$processor_min'";}}
    if ($processor_max) {if ($where ne '') {$where .= " AND article.processeur  <= '$processor_max'";} else {$where .= " AND article.processeur  <= '$processor_max'";}}
    if ($ram_min) {if ($where ne '') {$where .= " AND article.ram   >= '$ram_min'";} else {$where .= " AND article.ram   >= '$ram_min'";}}       
    if ($ram_max) {if ($where ne '') {$where .= " AND article.ram   <= '$ram_max'";			} else {$where .= " AND article.ram   <= '$ram_max'";}}
    if ($hard_drive_min) {if ($where ne '') {$where .= " AND article.disque_dur   >= '$hard_drive_min'";} else {$where .= " AND article.disque_dur   >= '$hard_drive_min'";}}       
    if ($hard_drive_max) {if ($where ne '') {$where .= " AND article.disque_dur   <= '$hard_drive_max'";} else {$where .= " AND article.disque_dur   <= '$hard_drive_max'";}}       
    if ($valeur) {$where .= " AND article.nom like '%$valeur%'";}
    
    if ($used) {
            $from .= ",etat_libelle_langue";
	if ($where ne ''){
            $where .= " AND article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue, libelle, langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}else {
            $where .= " article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue, libelle, langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}
       }    
    
    my  $total = '0';    
    my  ($d)= sqlSelect("count(id_article)", $from, $where ." AND ref_statut = '3'");
    my  $nb_page = arrondi ($d / 40, 1);
    my  $min_index = '0';
    my  $max_index = '40';

    for (my  $i = '0'; $i < $nb_page;$i++) {
	my $n2 = $i %= 10;
	if ($n2 ne '0') {
		#$string .= "<br />";
	}
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=dosearchtv&amp;min_index=$min_index&amp;session=$session_id&category=$category&type_ecran=$type_ecran&fabricant=$fabricant&tv_size_min=$tv_size_min&tv_size_max=$tv_size_max&price_min=$buy_price_min&price_max=$buy_price_max\"  class=\"menulink2\" ><-$i-></a>&#160;&nbsp;<img alt=\"\" alt=\"\" src=\"../images/next2.gif\" height=\"13px\" width=\"13px\">";		
	$min_index += 40;	
    }
    return $string;
}
#load search index result
sub doSearchInfoIndexed {
    my $category = $query->param("category");
    $category =~ s/[^\w ]//g;
    my  $subcategory = $query->param('subcat');
    $subcategory  =~ s/[^\w ]//g;    
    my $type_ecran = $query->param("type_ecran");
    $type_ecran =~ s/[^\w ]//g;
    my $fabricant = $query->param("fabricant");
    $fabricant =~ s/[^\w ]//g;
    my $tv_size_min = $query->param("tv_size_min");
    $tv_size_min =~ s/[^\w ]//g;
    my $tv_size_max = $query->param ("tv_size_max");
    $tv_size_max =~ s/[^\w ]//g;
    my $processor_min = $query->param("processor_min");
    $processor_min =~ s/[^\w ]//g;
    my $hard_drive_min = $query->param("hard_drive_min");
    $hard_drive_min =~ s/[^\w ]//g;
    my $hard_drive_max = $query->param("hard_drive_max");
    $hard_drive_max =~ s/[^\w ]//g;
    my $processor_max = $query->param("processor_max");
    $processor_max =~ s/[^\w ]//g;    
    my $ram_min = $query->param("ram_min");
    $ram_min =~ s/[^\w ]//g;
    my $ram_max = $query->param("ram_max");
    $ram_max =~ s/[^\w ]//g;
    my $buy_price_min = $query->param ("price_min");
    $buy_price_min =~ s/[^\w ]//g;
    my $buy_price_max = $query->param("price_max");
    $buy_price_max =~ s/[^\w ]//g;    
    my $ecran_dimension_min = $query->param("ecran_dimension_min");
    $ecran_dimension_min =~ s/[^\w ]//g;    
    my $ecran_dimension_max = $query->param("ecran_dimension_max");
    $ecran_dimension_max =~ s/[^\w ]//g;
    my $valeur = $query->param("valeur");
    $valeur =~ s/[^\w ]//g;
    my $used = $query->param("used");
    my $string;
    
    my $select = "DISTINCT article.nom,id_article, prix,pochette,marque";
        
    my  $from = "article,subcategorie_libelle_langue,type_ecran_libelle_langue";
    my  $where;

    if ($category) {
	$from .= ", categorie_libelle_langue";
	$where .= "article.ref_categorie = categorie_libelle_langue.ref_categorie_libelle_langue AND categorie_libelle_langue.ref_categorie = (SELECT ref_categorie FROM categorie_libelle_langue, libelle, langue WHERE libelle.libelle = '$category' AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
    }
    if ($subcategory) {
	$from .= ", subcategorie_libelle_langue";
	$where .= "article.ref_subcategorie = subcategorie_libelle_langue.ref_subcategorie AND subcategorie_libelle_langue.ref_subcategorie = (SELECT ref_subcategory FROM subcategorie_libelle_langue, libelle, langue WHERE libelle.libelle = '$subcategory' AND subcategorie_libelle_langue.ref_libelle = libelle.ref_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
    }
    if ($type_ecran) {if ($type_ecran ne '---------') {
	$where .= " AND article.ref_type_ecran  = type_ecran_libelle_langue.ref_type_ecran AND type_ecran_libelle_langue.ref_type_ecran = (SELECT libelle.libelle FROM type_ecran_libelle_langue, libelle, langue WHERE libelle.libelle = '$type_ecran' AND type_ecran_libelle_langue.ref_libelle = libelle.id_libelle AND type_ecran_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";}}
    if ($fabricant) {if ($fabricant ne '---------') {$where .= " AND article.marque = '$fabricant'";}}
    if ($tv_size_min) {$where .= " AND article.dimension >=  '$tv_size_min'";}
    if ($tv_size_max) {$where .= " AND article.dimension <=  '$tv_size_max'";}
    if ($ecran_dimension_min) {$where .= " AND article.dimension >=  '$ecran_dimension_min'";}
    if ($ecran_dimension_max) {$where .= " AND article.dimension <=  '$ecran_dimension_max'";}
    if ($buy_price_min) {$where .= " AND article.prix >= '$buy_price_min'";}
    if ($buy_price_max) {$where .= " AND article.prix <= '$buy_price_max'";	}
    if ($processor_min) {if ($where ne '') {$where .= " AND article.processeur  >= '$processor_min'";} else {$where .= " AND article.processeur  >= '$processor_min'";}}
    if ($processor_max) {if ($where ne '') {$where .= " AND article.processeur  <= '$processor_max'";} else {$where .= " AND article.processeur  <= '$processor_max'";}}
    if ($ram_min) {if ($where ne '') {$where .= " AND article.ram   >= '$ram_min'";} else {$where .= " AND article.ram   >= '$ram_min'";}}       
    if ($ram_max) {if ($where ne '') {$where .= " AND article.ram   <= '$ram_max'";			} else {$where .= " AND article.ram   <= '$ram_max'";}}
    if ($hard_drive_min) {if ($where ne '') {$where .= " AND article.disque_dur   >= '$hard_drive_min'";} else {$where .= " AND article.disque_dur   >= '$hard_drive_min'";}}       
    if ($hard_drive_max) {if ($where ne '') {$where .= " AND article.disque_dur   <= '$hard_drive_max'";} else {$where .= " AND article.disque_dur   <= '$hard_drive_max'";}}       
    if ($valeur) {$where .= " AND article.nom LIKE '%$valeur%'";}
    
    if ($used) {
        $from .= ",etat_libelle_langue";
	if ($where ne ''){
            $where .= " AND article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue, libelle, langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}else {
            $where .= " article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue, libelle, langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}
       }    

    my  $total = '0';    
    my  ($d)= sqlSelectMany($select, $from, $where ." AND ref_statut = '3'");
    my  $index_start = $query->param ("min_index") ;
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index") ;
    $index_end=~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d",$year+1900,$mon+1,$mday;
    
    if (!$index_start ) {$index_start = 0;}if (!$index_end ) {$index_end = 40;}
    $string = "<table style=\"border-width:thin; border-style:dotted;border-top-color:#94CEFA;border-right-color:#94CEFA;border-left-color:#94CEFA; border-right-width:2px; border-bottom-color:#94CEFA\" width=\"555\" border=\"0\"><tr bgcolor=\"#DBE4F8\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"120\">$SERVER{'article_name_label'}</td><td align=\"left\" width=\"120\">$SERVER{'fabricant'}</td><td align=\"left\">$SERVER{'article_price_label'}</td><td align=\"left\"></td></tr>";
    my  ($c)= sqlSelectMany($select, $from, $where ." LIMIT $index_start, $index_end");
    while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'price'},$ARTICLE{'image'},$ARTICLE{'fabricant'})=$c->fetchrow()) {
	$string .= "<tr><td align=\"left\"><img alt=\"\" alt=\"\" src=\"$ARTICLE{'image'}\"></td><td align=\"left\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'fabricant'}</td><td align=\"left\">$ARTICLE{'price'}</td><td align=\"left\">$ARTICLE{'depot'}</td></tr>";
    }
    $string .="</table>";    
    return $string;
}

sub doSearchTv {
    my $category = $query->param("category");    
    my  $subcategory = $query->param('subcategory');
    my $type_ecran = $query->param("type_ecran");
    my $fabricant = $query->param("fabricant");
    my $tv_size_min = $query->param("tv_size_min");
    my $tv_size_max = $query->param ("tv_size_max");
    my $buy_price_min = $query->param ("price_min");
    my $buy_price_max = $query->param("price_max");
    my $processor = $query->param("processor");
    my $hard_drive = $query->param("hard_drive");
    my $ram = $query->param("ram");
    my $valeur = $query->param("valeur");
    my $string;    
    my $select = "DISTINCT article.nom";        
    my  $from = "article,subcategorie_libelle_langue,type_ecran_libelle_langue";
    my  $where;
    if ($category) {
	$from .= "categorie_libelle_langue, libelle, langue";
        $where .= "article.ref_categorie = categorie_libelle_langue.ref_categorie AND categorie_libelle_langue.ref_categorie = 7 = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";	
    }
    if ($subcategory) {                                
	$from .= " ,libelle, langue";
	$where .= "  article.ref_subcategorie = subcategorie_libelle_langue.ref_subcategorie AND subcategorie_libelle_langue.ref_subcategorie = (SELECT ref_subcategorie FROM subcategorie_libelle_langue, libelle, langue WHERE libelle.libelle = '$subcategory' AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";	
    }
    if ($type_ecran) {if ($type_ecran ne '----------') {
	$where .= " AND article.ref_type_ecran  = type_ecran_libelle_langue.ref_type_ecran AND type_ecran_libelle_langue.ref_type_ecran = (SELECT libelle.libelle FROM type_ecran_libelle_langue, libelle, langue WHERE libelle.libelle = '$type_ecran' AND type_ecran_libelle_langue.ref_libelle = libelle.id_libelle AND type_ecran_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";}}
    if ($fabricant) {if ($fabricant ne '---------') {$where .= " AND article.marque = '$fabricant'";}}
    if ($tv_size_min) {$where .= " AND article.dimension >=  '$tv_size_min'";}
    if ($tv_size_max) {$where .= " AND article.dimension <=  '$tv_size_max'";}
    if ($buy_price_min) {$where .= " AND article.prix >= '$buy_price_min'";}
    if ($buy_price_max) {$where .= " AND article.prix <= '$buy_price_max'";}
    if ($valeur) {$where .= " AND article.nom LIKE '%$valeur%'";}
    if ($processor and $processor ne 'undefined') {$where .= " AND article.processeur = '$processor'";}
    if ($hard_drive and $hard_drive ne 'undefined') {$where .= " AND article.processeur = '%$hard_drive%'";}
    if ($ram and $ram ne 'undefined') {$where .= " AND article.ram = '%$ram%'";}
    my $used = $query->param("used");
    if ($used) {
	$from .= ",etat_libelle_langue";
	if ($where ne ''){
		$where .= " AND article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}else {
		$where .= " article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}
    }  
    
    my  $total = '0';    
    my  ($d)= $db->sqlSelect("count(id_article)", $from, $where ." AND ref_statut = '3'");
    my  $nb_page = arrondi ($d / 40, 1);
    my  $min_index = '0';
    my  $max_index = '40';

    for (my  $i = '0'; $i < $nb_page;$i++) {
	my $n2 = $i %= 10;
	if ($n2 ne '0') {
		#$string .= "<br />";
	}
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=dosearchtv&amp;min_index=$min_index&amp;session=$session_id&category=$category&type_ecran=$type_ecran&fabricant=$fabricant&tv_size_min=$tv_size_min&tv_size_max=$tv_size_max&price_min=$buy_price_min&price_max=$buy_price_max\"  class=\"menulink2\" ><-$i-></a>&#160;&nbsp;<img alt=\"\" alt=\"\" src=\"../images/next2.gif\" height=\"13px\" width=\"13px\">";		
	$min_index += 40;	
    }
    return $string;
}
#load search index result
sub doSearchTvIndexed {
    my $category = $query->param("category");    
    my  $subcategory = $query->param('subcategory');
    my $type_ecran = $query->param("type_ecran");
    my $fabricant = $query->param("fabricant");
    my $tv_size_min = $query->param("tv_size_min");
    my $tv_size_max = $query->param ("tv_size_max");
    my $buy_price_min = $query->param ("price_min");
    my $buy_price_max = $query->param("price_max");
    my $processor = $query->param("processor");
    my $hard_drive = $query->param("hard_drive");
    my $ram = $query->param("ram");
    my $valeur = $query->param("valeur");
    my $string;    
    my $select = "DISTINCT article.nom,id_article, prix,pochette,marque";        
    my  $from = "article,subcategorie_libelle_langue,type_ecran_libelle_langue";
    my  $where;
    if ($category) {
	$from .= " ,categorie_libelle_langue,libelle,langue";
	$where .= "article.ref_categorie = categorie_libelle_langue.ref_categorie AND categorie_libelle_langue.ref_categorie = 7 AND categorie_libelle_langue.ref_libelle = libelle.id_libelle AND categorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
    }
    if ($subcategory) {
	$where .= "  article.ref_subcategorie = subcategorie_libelle_langue.ref_subcategorie AND subcategorie_libelle_langue.ref_subcategorie = (SELECT ref_subcategorie FROM subcategorie_libelle_langue, libelle, langue WHERE libelle.libelle = '$subcategory' AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
    }
    if ($type_ecran) {if ($type_ecran ne '---------') {
	$where .= " AND article.ref_type_ecran  = type_ecran_libelle_langue.ref_type_ecran AND type_ecran_libelle_langue.ref_type_ecran = (SELECT libelle.libelle FROM type_ecran_libelle_langue, libelle, langue WHERE libelle.libelle = '$type_ecran' AND type_ecran_libelle_langue.ref_libelle = libelle.id_libelle AND type_ecran_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";}}
    if ($fabricant) {if ($fabricant ne '----------') {$where .= " AND article.marque = '$fabricant'";}}
    if ($tv_size_min) {$where .= " AND article.dimension >=  '$tv_size_min'";}
    if ($tv_size_max) {$where .= " AND article.dimension <=  '$tv_size_max'";}
    if ($buy_price_min) {$where .= " AND article.prix >= '$buy_price_min'";}
    if ($buy_price_max) {$where .= " AND article.prix <= '$buy_price_max'";}
    if ($valeur) {$where .= " AND article.nom LIKE '%$valeur%'";}
    if ($processor and $processor ne 'undefined') {$where .= " AND article.processeur = '$processor'";}
    if ($hard_drive and $hard_drive ne 'undefined') {$where .= " AND article.processeur = '%$hard_drive%'";}
    if ($ram and $ram ne 'undefined') {$where .= " AND article.ram = '%$ram%'";}
    
    my $used = $query->param("used");

    if ($used) {
	        $from .= ",etat_libelle_langue";
	if ($where ne ''){
            $where .= " AND article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue, libelle, langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}else {
            $where .= " article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue, libelle, langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}
       } 

    my  $total = '0';my  ($d)= $db->sqlSelectMany($select, $from, $where ." AND ref_statut = '3'");
    my  $index_start = $query->param ("min_index") ;$index_start=~ s/[^A-Za-z0-9 ]//;my  $index_end = $query->param ("max_index");$index_end=~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d",$year+1900,$mon+1,$mday;    
    if (!$index_start ) {$index_start = 0;}
    if (!$index_end ) {$index_end = 40;}
    $string = "<table style=\"border-width:thin; border-style:dotted; border-top-color:#94CEFA;border-right-color:#94CEFA;border-left-color:#94CEFA; border-bottom-color:#94CEFA\" width=\"555\" border=\"0\"><tr bgcolor=\"#DBE4F8\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\" width=\"120\">$SERVER{'article_name_label'}</td><td align=\"left\" width=\"120\">$SERVER{'fabricant'}</td><td align=\"left\">$SERVER{'article_price_label'}</td><td align=\"left\"></td></tr>";    
    my  ($c)= $db->sqlSelectMany($select, $from, $where ." LIMIT $index_start, $index_end");
    while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'price'},$ARTICLE{'image'},$ARTICLE{'fabricant'})=$c->fetchrow()) {
	$string .= "<tr><td align=\"left\"><img alt=\"\" alt=\"\" src=\"$ARTICLE{'image'}\"></td><td align=\"left\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'fabricant'}</td><td align=\"left\">$ARTICLE{'price'}</td><td align=\"left\">$ARTICLE{'depot'}</td></tr>";
    }
    $string .="</table>";    
    return $string;
}


sub searchMoto {
    my  $category = $query->param ('category');
    $category  =~ s/[^\w ]//g;
    my  $subcategory = $query->param('subcat');
    $subcategory  =~ s/[^\w ]//g;
    my $fabricant = $query->param ('fabricant');
    $fabricant  =~ s/[^\w ]//g;
    my $valeur = $query->param ('valeur');
    $valeur  =~ s/[^\w ]//g;
    my $content;
    $session = new CGI::Session("driver:File", $session_id, {Directory=>"$session_dir"});
    my $level = $session->param("level");
	if ($level eq '2') {
	    $LINK{'admin'} = "<a href=\"javascript:void(0)\" class=\"menulink\"  onclick=\"window.open('/cgi-bin/recordz.cgi?lang=$lang&amp;page=cms_manage_article&amp;session=$session_id;','MyWindow','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=no,width=800,height=600,left=20,top=20')\">Admin</a>";
	}
	else {
	    $LINK{'admin'} = "";
	}
    
    
    my  $string = doSearchMoto ($category, $subcategory,$fabricant, $valeur);
    my  $string2 = doSearchMotoIndexed ($category, $subcategory,$fabricant, $valeur);
    #my  $string3 = getSearchDepot();
    #my $string4 = weekNews ();
    open (FILE, "<$dir/dosearchmoto.html") or die "cannot open file $dir/dosearchmoto.html";
    my $menu = loadMenu();
    my $categories = $lp->loadCategories();
    #my $cats = getCat();
    while (<FILE>) {	
	s/\$LABEL{'([\w]+)'}/ exists $SERVER{$1} ? $SERVER{$1} : $1 /eg; 
	s/\$LANG/$lang/g;
	s/\$ERROR{'([\w]+)'}//g;
	s/\$OPTIONS{'categories'}/$categories/g;
	s/\$ARTICLE{'index_table'}/$string/g;
	s/\$ARTICLE{'search'}/$string2/g;
	s/\$ARTICLE{'main_menu'}/$menu/g;
	s/\$LINK{'admin'}/$LINK{'admin'}/g;
	s/\$SESSIONID/$session_id/g;
	$content .= $_;	
    }
	$content = Compress::Zlib::memGzip($content)  if $can_do_gzip; ;
	print "Content-Length: ", length($content) , "\n";
	print "Content-Encoding: gzip\n" ;
	print "Content-Type: text/html\n\n"; 
	print $content;
        close (FILE);	

}

sub searchWine {
    my  $category = $query->param ('category');
    $category  =~ s/[^\w ]//g;
    my  $subcategory = $query->param('subcat');
    $subcategory  =~ s/[^\w ]//g;
    my $fabricant = $query->param ('fabricant');
    $fabricant  =~ s/[^\w ]//g;
    my $valeur = $query->param ('valeur');
    $valeur  =~ s/[^\w ]//g;
    my $content;
    $session = new CGI::Session("driver:File", $session_id, {Directory=>"$session_dir"});
    my $level = $session->param("level");
	if ($level eq '2') {
	    $LINK{'admin'} = "<a href=\"javascript:void(0)\" class=\"menulink\"  onclick=\"window.open('/cgi-bin/recordz.cgi?lang=$lang&amp;page=cms_manage_article&amp;session=$session_id;','MyWindow','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=no,width=800,height=600,left=20,top=20')\">Admin</a>";
	}
	else {
	    $LINK{'admin'} = "";
	}
    
    
    my  $string = doSearchWine ($category, $subcategory,$fabricant, $valeur);
    my  $string2 = doSearchWineIndexed ($category, $subcategory,$fabricant, $valeur);
    #my  $string3 = getSearchDepot();
    #my $string4 = weekNews ();
    open (FILE, "<$dir/dosearchmoto.html") or die "cannot open file $dir/dosearchmoto.html";
    my $menu = loadMenu();
    my $categories = $lp->loadCategories();
    while (<FILE>) {	
	s/\$LABEL{'([\w]+)'}/ exists $SERVER{$1} ? $SERVER{$1} : $1 /eg; 
	s/\$LANG/$lang/g;
	s/\$ERROR{'([\w]+)'}//g;
	s/\$ARTICLE{'index_table'}/$string/g;
	s/\$ARTICLE{'search'}/$string2/g;
	s/\$ARTICLE{'main_menu'}/$menu/g;
	s/\$OPTIONS{'categories'}/$categories/g;
	s/\$SESSIONID/$session_id/g;
	$content .= $_;	
    }
	$content = Compress::Zlib::memGzip($content)  if $can_do_gzip; ;
	print "Content-Length: ", length($content) , "\n";
	print "Content-Encoding: gzip\n" ;
	print "Content-Type: text/html\n\n"; 
	print $content;
        close (FILE);	

}

sub searchBoat {
    my  $category = $query->param ('category');
    $category  =~ s/[^\w ]//g;
    my  $subcategory = $query->param('subcat');
    $subcategory  =~ s/[^\w ]//g;
    my $fabricant = $query->param ('fabricant');
    $fabricant  =~ s/[^\w ]//g;
    my $valeur = $query->param ('valeur');
    $valeur  =~ s/[^\w ]//g;
    my $content;
    $session = new CGI::Session("driver:File", $session_id, {Directory=>"$session_dir"});
    my $level = $session->param("level");
	if ($level eq '2') {
	    $LINK{'admin'} = "<a href=\"javascript:void(0)\" class=\"menulink\"  onclick=\"window.open('/cgi-bin/recordz.cgi?lang=$lang&amp;page=cms_manage_article&amp;session=$session_id;','MyWindow','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=no,width=800,height=600,left=20,top=20')\">Admin</a>";
	}
	else {
	    $LINK{'admin'} = "";
	}
    
    
    my  $string = doSearchBoat ($category, $subcategory,$fabricant, $valeur);
    my  $string2 = doSearchBoatIndexed ($category, $subcategory,$fabricant, $valeur);
    my $categories = $lp->loadCategories();
    #my $string4 = weekNews ();
    open (FILE, "<$dir/dosearchmoto.html") or die "cannot open file $dir/dosearchmoto.html";
    my $menu = loadMenu();
    #my $cats = getCat();
    while (<FILE>) {	
	s/\$LABEL{'([\w]+)'}/ exists $SERVER{$1} ? $SERVER{$1} : $1 /eg; 
	s/\$LANG/$lang/g;
	s/\$ERROR{'([\w]+)'}//g;
	s/\$ARTICLE{'index_table'}/$string/g;
	s/\$ARTICLE{'search'}/$string2/g;
	s/\$ARTICLE{'main_menu'}/$menu/g;
	s/\$LINK{'admin'}/$LINK{'admin'}/g;
	s/\$OPTIONS{'categories'}/$categories/g;
	s/\$SESSIONID/$session_id/g;
	$content .= $_;	
    }
	$content = Compress::Zlib::memGzip($content)  if $can_do_gzip; ;
	print "Content-Length: ", length($content) , "\n";
	print "Content-Encoding: gzip\n" ;
	print "Content-Type: text/html\n\n"; 
	print $content;
        close (FILE);	

}

sub searchDvd {
    my  $category = $query->param ('category');
    $category  =~ s/[^\w ]//g;
    my  $subcategory = $query->param('subcat');
    $subcategory  =~ s/[^\w ]//g;
    my $fabricant = $query->param ('fabricant');
    $fabricant  =~ s/[^\w ]//g;
    my $valeur = $query->param ('valeur');
    $valeur  =~ s/[^\w ]//g;
    my $content;
    $session = new CGI::Session("driver:File", $session_id, {Directory=>"$session_dir"});
    my $level = $session->param("level");
	if ($level eq '2') {
	    $LINK{'admin'} = "<a href=\"javascript:void(0)\" class=\"menulink\"  onclick=\"window.open('/cgi-bin/recordz.cgi?lang=$lang&amp;page=cms_manage_article&amp;session=$session_id;','MyWindow','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=no,width=800,height=600,left=20,top=20')\">Admin</a>";
	}
	else {
	    $LINK{'admin'} = "";
	}
    
    
    my  $string = doSearchDvd ($category, $subcategory,$fabricant, $valeur);
    my  $string2 = doSearchDvdIndexed ($category, $subcategory,$fabricant, $valeur);
    #my  $string3 = getSearchDepot();
    my $categories = $lp->loadCategories();
    open (FILE, "<$dir/dosearchmoto.html") or die "cannot open file $dir/dosearchmoto.html";
    my $menu = loadMenu();
    #my $cats = getCat();
    while (<FILE>) {	
	s/\$LABEL{'([\w]+)'}/ exists $SERVER{$1} ? $SERVER{$1} : $1 /eg; 
	s/\$LANG/$lang/g;
	s/\$ERROR{'([\w]+)'}//g;
	s/\$ARTICLE{'index_table'}/$string/g;
	s/\$ARTICLE{'search'}/$string2/g;
	s/\$ARTICLE{'main_menu'}/$menu/g;
	s/\$LINK{'admin'}/$LINK{'admin'}/g;
	s/\$OPTIONS{'categories'}/$categories/g;
	s/\$SESSIONID/$session_id/g;
	$content .= $_;	
    }
	$content = Compress::Zlib::memGzip($content)  if $can_do_gzip; ;
	print "Content-Length: ", length($content) , "\n";
	print "Content-Encoding: gzip\n" ;
	print "Content-Type: text/html\n\n"; 
	print $content;
        close (FILE);	

}

sub searchBook {
    my  $category = $query->param ('category');
    $category  =~ s/[^\w ]//g;
    my  $subcategory = $query->param('subcat');
    $subcategory  =~ s/[^\w ]//g;
    my $fabricant = $query->param ('fabricant');
    $fabricant  =~ s/[^\w ]//g;
    my $valeur = $query->param ('valeur');
    $valeur  =~ s/[^\w ]//g;
    my $content;
    $session = new CGI::Session("driver:File", $session_id, {Directory=>"$session_dir"});
    my $level = $session->param("level");
	if ($level eq '2') {
	    $LINK{'admin'} = "<a href=\"javascript:void(0)\" class=\"menulink\"  onclick=\"window.open('/cgi-bin/recordz.cgi?lang=$lang&amp;page=cms_manage_article&amp;session=$session_id;','MyWindow','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=no,width=800,height=600,left=20,top=20')\">Admin</a>";
	}
	else {
	    $LINK{'admin'} = "";
	}
    
    
    my  $string = doSearchBook ($category, $subcategory,$fabricant, $valeur);
    my  $string2 = doSearchBookIndexed ($category, $subcategory,$fabricant, $valeur);
    my $categories = $lp->loadCategories();
    #my $string4 = weekNews ();
    open (FILE, "<$dir/dosearchbook.html") or die "cannot open file $dir/dosearchbook.html";
    my $menu = loadMenu();
    #my $cats = getCat();
    while (<FILE>) {	
	s/\$LABEL{'([\w]+)'}/ exists $SERVER{$1} ? $SERVER{$1} : $1 /eg; 
	s/\$LANG/$lang/g;
	s/\$ERROR{'([\w]+)'}//g;
	s/\$ARTICLE{'index_table'}/$string/g;
	s/\$ARTICLE{'search'}/$string2/g;
	s/\$ARTICLE{'main_menu'}/$menu/g;
	s/\$LINK{'admin'}/$LINK{'admin'}/g;
	s/\$OPTIONS{'categories'}/$categories/g;
	s/\$SESSIONID/$session_id/g;
	$content .= $_;	
    }
	$content = Compress::Zlib::memGzip($content)  if $can_do_gzip; ;
	print "Content-Length: ", length($content) , "\n";
	print "Content-Encoding: gzip\n" ;
	print "Content-Type: text/html\n\n"; 
	print $content;
        close (FILE);	

}

sub doSearchMoto {
    my $fabricant = $query->param("fabricant");
    $fabricant =~ s/[^\w ]//g;
    my $type = $query->param("subcategory");
    $type =~ s/[^\w ]//g;
    my $year_fabrication_min = $query->param("year_fabrication_min");
    $year_fabrication_min =~ s/[^\w ]//g;
    my $year_fabrication_max = $query->param("year_fabrication_max");
    $year_fabrication_max =~ s/[^\w ]//g;
    my $km_min = $query->param("km_min");
    $km_min  =~ s/[^\w ]//g;
    my $km_max = $query->param("km_max");
    $km_max  =~ s/[^\w ]//g;
    my $horse_nbr_min = $query->param ("horse_nbr_min");
    $horse_nbr_min  =~ s/[^\w ]//g;
    my $cyclindre_min = $query->param ("cylindre_min");
    $horse_nbr_min  =~ s/[^\w ]//g;
    my $cyclindre_max = $query->param ("cylindre_max");
    $horse_nbr_min  =~ s/[^\w ]//g;
    my $horse_nbr_max = $query->param ("horse_nbr_max");
    $horse_nbr_max  =~ s/[^\w ]//g;
    my $buy_price_min = $query->param ("price_min");
    $buy_price_min   =~ s/[^\w ]//g;
    my $buy_price_max = $query->param("price_max");
    $buy_price_max   =~ s/[^\w ]//g;
    my $withclim = $query->param("withclim");
    $withclim   =~ s/[^\w ]//g;
    my $motorisation = $query->param("motorisation");
    $motorisation  =~ s/[^\w ]//g;
    my $used = $query->param("used");
    my $string;
    
    my $select = "DISTINCT article.nom";
        
    my  $from = "article";
    my  $where;
    my $cl_value;
    if ($used) {
	        $from .= ",etat_libelle_langue";
	if ($where ne ''){
            $where .= " AND article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue, libelle, langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}else {
            $where .= " article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue, libelle, langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}
       } 

    if ($fabricant){
	if ($where ne ''){
	    $where .= " and article.marque = '$fabricant'";	    
        } else {
	    $where .= " article.marque = '$fabricant'";
	}
    }
    if ($type) {
        if ($where ne '') {
	    $from .= ",subcategorie_libelle_langue";
            $where .= " AND article.ref_subcategorie = subcategorie_libelle_langue.ref_subcategorie AND subcategorie_libelle_langue.ref_subcategorie = (SELECT ref_subcategorie FROM subcategorie_libelle_langue, libelle, langue WHERE libelle.libelle = '$type' AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
            }
        else {
            $from .= ",subcategorie_libelle_langue";
	    $where .= " article.ref_subcategorie = subcategorie_libelle_langue.ref_subcategorie AND subcategorie_libelle_langue.ref_subcategorie = (SELECT libelle.libelle FROM subcategorie_libelle_langue, libelle, langue WHERE libelle.libelle = '$type' AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
            }
    }
    
    if ($year_fabrication_min) {if ($where ne '') {$where .= " AND article.annee >= '$year_fabrication_min'";}else {$where .= " article.annee >= '$year_fabrication_min'";}}
    if ($year_fabrication_max) {if ($where ne '') {$where .= " AND article.annee <= '$year_fabrication_min'";}else {$where .= " article.annee <= '$year_fabrication_min'";}}
    if ($motorisation and $motorisation ne '') {if ($where ne '') {$where .= " AND article.essence_ou_diesel = id_type_essence AND type_essence_$lang.nom = '$motorisation'";}else {$where .= " article.essence_ou_diesel  = id_type_essence AND type_essence_$lang.nom = '$motorisation'";}$from .= ",type_essence_$lang";}
    if ($km_min) {if ($where ne '') {$where .= "AND article.nb_km >= '$km_min'";}else {$where .= " article.nb_km >= '$km_min'";}}
    if ($withclim and $withclim ne '---------') {if ($withclim eq 'Yes' or $withclim eq 'Oui' or $withclim eq 'Ya') {$cl_value = 1;}else {$cl_value = 0;}if ($where ne '') {$where .= " AND article.clima = '$cl_value'";}else {$where .= " article.clima = '$cl_value'";}}
    if ($km_max) {if ($where ne '') {$where .= "AND article.nb_km <= '$km_max'";}else {$where .= " article.nb_km <= '$km_max'";}}    
    if ($horse_nbr_min) {if ($where ne '') {$where .= " AND nb_cheveaux  >= '$horse_nbr_min'";}else {$where .= "  nb_cheveaux  >= '$horse_nbr_min'";}}if ($horse_nbr_max) {
    if ($where ne '') {$where .= " AND nb_cheveaux  <= '$horse_nbr_max'";}else {$where .= "  nb_cheveaux  <= '$horse_nbr_max'";	} }
    if ($buy_price_min) {if ($where ne '') {$where .= " AND article.prix >= '$buy_price_min'";}else {$where .= "  article.prix >= '$buy_price_min'";}}
    if ($buy_price_max) {if ($where ne '') {$where .= " AND article.prix <= '$buy_price_max'";}else {$where .= "  article.prix <= '$buy_price_max'";}}
    if ($cyclindre_min) {if ($where ne '') {$where .= " AND article.nb_cylindre >= '$cyclindre_min'";}else {$where .= "  article.nb_cylindre >= '$cyclindre_min'";}}    
    if ($cyclindre_max) {if ($where ne '') {$where .= " AND article.nb_cylindre <= '$cyclindre_max'";}else {$where .= "  article.nb_cylindre <= '$cyclindre_max'";}}    

    my  $total = '0';
    my $add_where;
    if ($where eq '') {
	$add_where = "ref_statut = '3' AND article.ref_categorie = '6')";
    }else {
	$add_where = "AND ref_statut = '3' AND article.ref_categorie = '6'";
    }
    my  ($d)= $db->sqlSelect("count(id_article)", $from, $where ." $add_where");
    my  $nb_page = arrondi ($d / 40, 1);
    my  $min_index = '0';
    my  $max_index = '40';

    for (my  $i = '0'; $i < $nb_page;$i++) {
	my $n2 = $i %= 10;
	if ($n2 ne '0') {
		#$string .= "<br />";
	}
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=dosearchcar&amp;min_index=$min_index&amp;session=$session_id&fabricant=$fabricant&type=$type&year_fabrication_min=$year_fabrication_min&year_fabrication_max=$year_fabrication_max&km_min=$km_min&km_max=$km_max&horse_nbr_min=$horse_nbr_min&horse_nbr_max=$horse_nbr_max&price_min=$buy_price_min&price_max=$buy_price_max&withclim=$withclim&motorisation=$motorisation\"  class=\"menulink2\" ><-$i-></a>&#160;&nbsp;<img alt=\"\" alt=\"\" src=\"../images/next2.gif\" height=\"13px\" width=\"13px\">";		
	$min_index += 40;	
    }
    return $string;
}
#load search index result
sub doSearchMotoIndexed {

    my $fabricant = $query->param("fabricant");
    $fabricant =~ s/[^\w ]//g;
    my $type = $query->param("subcategory");
    $type =~ s/[^\w ]//g;
    my $year_fabrication_min = $query->param("year_fabrication_min");
    $year_fabrication_min =~ s/[^\w ]//g;
    my $year_fabrication_max = $query->param("year_fabrication_max");
    $year_fabrication_max =~ s/[^\w ]//g;
    my $km_min = $query->param("km_min");
    $km_min  =~ s/[^\w ]//g;
    my $km_max = $query->param("km_max");
    $km_max  =~ s/[^\w ]//g;
    my $horse_nbr_min = $query->param ("horse_nbr_min");
    $horse_nbr_min  =~ s/[^\w ]//g;
    my $horse_nbr_max = $query->param ("horse_nbr_max");
    $horse_nbr_max  =~ s/[^\w ]//g;
    my $buy_price_min = $query->param ("price_min");
    $buy_price_min   =~ s/[^\w ]//g;
    my $cyclindre_min = $query->param ("cylindre_min");
    $cyclindre_min  =~ s/[^\w ]//g;
    my $cyclindre_max = $query->param ("cylindre_max");
    $cyclindre_max  =~ s/[^\w ]//g;
    my $buy_price_max = $query->param("price_max");
    $buy_price_max   =~ s/[^\w ]//g;
    my $withclim = $query->param("withclim");
    $withclim   =~ s/[^\w ]//g;
    my $motorisation = $query->param("motorisation");
    $motorisation  =~ s/[^\w ]//g;
    my $string;
    my $cl_value;
    my $used = $query->param("used");
    #$ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'price'},$ARTICLE{'image'},$ARTICLE{'fabricant'},$ARTICLE{'km'}
    my $select = "DISTINCT article.nom,id_article,prix,pochette,marque,nb_km";
        
    my  $from = "article";
    my  $where;
   if ($used) {
	        $from .= ",etat_libelle_langue";
	if ($where ne ''){
            $where .= " AND article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue, libelle, langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}else {
            $where .= " article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue, libelle, langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}
       } 


    if ($fabricant) {
	if ($where ne ''){
	    $where .= "AND article.marque = '$fabricant'";
	    }else {
	    $where .= " article.marque = '$fabricant'";
	}
    }
    if ($type) {
        if ($where ne '') {
	    $from .= ", subcategorie_libelle_langue";
            $where .= " AND article.ref_subcategorie = subcategorie_libelle_langue.ref_subcategorie AND subcategorie_libelle_langue.ref_subcategorie = (SELECT ref_subcategorie FROM subcategorie_libelle_langue, libelle, langue WHERE libelle.libelle = '$type' AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' and libelle.libelle = '$type')";
            }
        else {
		$from .= ", subcategorie_libelle_langue";
                $where .= " article.ref_subcategorie = subcategorie_libelle_langue.ref_subcategorie AND subcategorie_libelle_langue.ref_subcategorie = (SELECT ref_subcategorie FROM subcategorie_libelle_langue, libelle, langue WHERE libelle.libelle = '$type' AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'  and libelle.libelle = '$type')";
                }
    }
    if ($year_fabrication_min) {if ($where ne '') {$where .= " AND article.annee >= '$year_fabrication_min'";}else {$where .= " article.annee >= '$year_fabrication_min'";}}
    if ($year_fabrication_max) {if ($where ne '') {$where .= " AND article.annee <= '$year_fabrication_min'";}else {$where .= " article.annee <= '$year_fabrication_min'";}}
    if ($motorisation and $motorisation ne '') {if ($where ne '') {$where .= " AND article.essence_ou_diesel = id_type_essence AND type_essence_$lang.nom = '$motorisation'";}else {$where .= " article.essence_ou_diesel  = id_type_essence AND type_essence_$lang.nom = '$motorisation'";}$from .= ",type_essence_$lang";}
    if ($km_min) {if ($where ne '') {$where .= "AND article.nb_km >= '$km_min'";}else {$where .= " article.nb_km >= '$km_min'";}}
    if ($withclim and $withclim ne '---------') {if ($withclim eq 'Yes' or $withclim eq 'Oui' or $withclim eq 'Ya') {$cl_value = 1;}else {$cl_value = 0;}if ($where ne '') {$where .= " AND article.clima = '$cl_value'";}else {$where .= " article.clima = '$cl_value'";}}
    if ($km_max) {if ($where ne '') {$where .= "AND article.nb_km <= '$km_max'";}else {$where .= " article.nb_km <= '$km_max'";}}    
    if ($horse_nbr_min) {if ($where ne '') {$where .= " AND nb_cheveaux  >= '$horse_nbr_min'";}else {$where .= "  nb_cheveaux  >= '$horse_nbr_min'";}}if ($horse_nbr_max) {
    if ($where ne '') {$where .= " AND nb_cheveaux  <= '$horse_nbr_max'";}else {$where .= "  nb_cheveaux  <= '$horse_nbr_max'";	} }
    if ($buy_price_min) {if ($where ne '') {$where .= " AND article.prix >= '$buy_price_min'";}else {$where .= "  article.prix >= '$buy_price_min'";}}
    if ($buy_price_max) {if ($where ne '') {$where .= " AND article.prix <= '$buy_price_max'";}else {$where .= "  article.prix <= '$buy_price_max'";}}
    if ($cyclindre_min) {if ($where ne '') {$where .= " AND article.nb_cylindre >= '$cyclindre_min'";}else {$where .= "  article.nb_cylindre >= '$cyclindre_min'";}}    
    if ($cyclindre_max) {if ($where ne '') {$where .= " AND article.nb_cylindre <= '$cyclindre_max'";}else {$where .= "  article.nb_cylindre <= '$cyclindre_max'";}}    

    my  $add_where;
    if ($where eq '') {
	$add_where = " AND ref_statut = '3' AND article.ref_categorie = '6'"; }else {
	$add_where = " AND ref_statut = '3' AND article.ref_categorie = '6'";
	}
    my  $index_start = $query->param ("min_index") ;
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index") ;
    $index_end=~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d",$year+1900,$mon+1,$mday;    
    if (!$index_start ) {$index_start = 0;}
    if (!$index_end ) {$index_end = 40;}

    my  $total = '0';
    
    my  ($d)= $db->sqlSelectMany($select, $from, $where ." $add_where LIMIT $index_start, $index_end");

    $string = "<table style=\"border-width:thin; border-style:dotted;border-top-color:#94CEFA;border-right-color:#94CEFA;border-left-color:#94CEFA; border-right-width:2px; border-bottom-color:#94CEFA\" width=\"555\" border=\"0\"><tr bgcolor=\"#DBE4F8\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\">Nom</td><td align=\"left\">$SERVER{'fabricant'}</td><td align=\"left\">$SERVER{'article_price_label'}</td><td align=\"left\">Km</td></tr>";
    while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'price'},$ARTICLE{'image'},$ARTICLE{'fabricant'},$ARTICLE{'km'})=$d->fetchrow()) {
	$string .= "<tr><td align=\"left\"><img alt=\"\" alt=\"\" src=\"$ARTICLE{'image'}\"></td><td align=\"left\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'fabricant'}</td><td align=\"left\">$ARTICLE{'price'}</td><td align=\"left\">$ARTICLE{'km'}</td></tr>";
    }
    $string .="</table>";    
    return $string;
}

sub searchCar {
      my  $category = $query->param ('category');
    $category  =~ s/[^\w ]//g;
    my  $subcategory = $query->param('subcat');
    $subcategory  =~ s/[^\w ]//g;
    my $fabricant = $query->param ('fabricant');
    $fabricant  =~ s/[^\w ]//g;
    my $valeur = $query->param ('valeur');
    $valeur  =~ s/[^\w ]//g;
    my $content;
    $session = new CGI::Session("driver:File", $session_id, {Directory=>"$session_dir"});
    my $level = $session->param("level");
	if ($level eq '2') {
	    $LINK{'admin'} = "<a href=\"javascript:void(0)\" class=\"menulink\"  onclick=\"window.open('/cgi-bin/recordz.cgi?lang=$lang&amp;page=cms_manage_article&amp;session=$session_id;','MyWindow','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=no,width=800,height=600,left=20,top=20')\">Admin</a>";
	}
	else {
	    $LINK{'admin'} = "";
	}
    
    my $categories = $lp->loadCategories();
    my  $string = doSearchCar ($category, $subcategory, $fabricant, $valeur);
    my  $string2 = doSearchCarIndexed ($category, $subcategory, $fabricant, $valeur);
    open (FILE, "<$dir/dosearchcar.html") or die "cannot open file $dir/dosearchcar.html";
    my $menu = loadMenu();
    while (<FILE>) {	
	s/\$LABEL{'([\w]+)'}/ exists $SERVER{$1} ? $SERVER{$1} : $1 /eg; 
	s/\$LANG/$lang/g;
	s/\$ERROR{'([\w]+)'}//g;
	s/\$ARTICLE{'index_table'}/$string/g;
	s/\$LINK{'admin'}/$LINK{'admin'}/g;
	s/\$OPTIONS{'categories'}/$categories/g;
	s/\$SESSIONID/$session_id/g;
	s/\$ARTICLE{'main_menu'}/$menu/g;
	s/\$ARTICLE{'search'}/$string2/g;
	$content .= $_;	
    }
	$content = Compress::Zlib::memGzip($content)  if $can_do_gzip; ;
	print "Content-Length: ", length($content) , "\n";
	print "Content-Encoding: gzip\n" ;
	print "Content-Type: text/html\n\n"; 
	print $content;
        close (FILE);	
}


sub doSearchCar {
    my $fabricant = $query->param("fabricant");
    $fabricant =~ s/[^\w ]//g;
    my $type = $query->param("subcategory");
    $type =~ s/[^\w ]//g;
    my $year_fabrication_min = $query->param("year_fabrication_min");
    $year_fabrication_min =~ s/[^\w ]//g;
    my $year_fabrication_max = $query->param("year_fabrication_max");
    $year_fabrication_max =~ s/[^\w ]//g;
    my $km_min = $query->param("km_min");
    $km_min  =~ s/[^\w ]//g;
    my $km_max = $query->param("km_max");
    $km_max  =~ s/[^\w ]//g;
    my $horse_nbr_min = $query->param ("horse_nbr_min");
    $horse_nbr_min  =~ s/[^\w ]//g;
    my $cyclindre_min = $query->param ("cylindre_min");
    $horse_nbr_min  =~ s/[^\w ]//g;
    my $cyclindre_max = $query->param ("cylindre_max");
    $horse_nbr_min  =~ s/[^\w ]//g;

    my $horse_nbr_max = $query->param ("horse_nbr_max");
    $horse_nbr_max  =~ s/[^\w ]//g;
    my $buy_price_min = $query->param ("price_min");
    $buy_price_min   =~ s/[^\w ]//g;
    my $buy_price_max = $query->param("price_max");
    $buy_price_max   =~ s/[^\w ]//g;
    my $withclim = $query->param("withclim");
    $withclim   =~ s/[^\w ]//g;
    my $motorisation = $query->param("motorisation");
    $motorisation  =~ s/[^\w ]//g;
    my $used = $query->param("used");
    my $string;
    
    my $select = "DISTINCT article.nom";
        
    my  $from = "article";
    my  $where;
    my $cl_value;

    if ($fabricant) {$where .= "article.marque = '$fabricant'";}
        if ($type) {
        if ($where ne '') {
	    $from .= ",subcategorie_libelle_langue";
            $where .= " AND article.ref_subcategorie = subcategorie_libelle_langue.ref_subcategorie AND subcategorie_libelle_langue = (SELECT libelle.libelle FROM subcategorie_libelle_langue, libelle, langue WHERE libelle.libelle = '$type' AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie.ref_langue = langue.id_langue AND langue.key = '$lang')";
            }
        else {
		$from .= ",subcategorie_libelle_langue";
	        $where .= " article.ref_subcategorie = subcategorie_libelle_langue.ref_subcategorie AND subcategorie_libelle_langue.ref_subcategorie = (SELECT libelle.libelle FROM subcategorie_libelle_langue, libelle, langue WHERE libelle.libelle = '$type' AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie.ref_langue = langue.id_langue AND langue.key = '$lang')";
                }
	}
    if ($year_fabrication_min) {if ($where ne '') {$where .= " AND article.annee >= '$year_fabrication_min'";}else {$where .= " article.annee >= '$year_fabrication_min'";}}
    if ($year_fabrication_max) {if ($where ne '') {$where .= " AND article.annee <= '$year_fabrication_min'";}else {$where .= " article.annee <= '$year_fabrication_min'";}}
    if ($motorisation and $motorisation ne '') {if ($where ne '') {$where .= " AND article.essence_ou_diesel = id_type_essence AND type_essence_$lang.nom = '$motorisation'";}else {$where .= " article.essence_ou_diesel  = id_type_essence AND type_essence_$lang.nom = '$motorisation'";}$from .= ",type_essence_$lang";}
    if ($km_min) {if ($where ne '') {$where .= "AND article.nb_km >= '$km_min'";}else {$where .= " article.nb_km >= '$km_min'";}}
    if ($withclim and $withclim ne '---------') {if ($withclim eq 'Yes' or $withclim eq 'Oui' or $withclim eq 'Ya') {$cl_value = 1;}else {$cl_value = 0;}if ($where ne '') {$where .= " AND article.clima = '$cl_value'";}else {$where .= " article.clima = '$cl_value'";}}
    if ($km_max) {if ($where ne '') {$where .= "AND article.nb_km <= '$km_max'";}else {$where .= " article.nb_km <= '$km_max'";}}    
    if ($horse_nbr_min) {if ($where ne '') {$where .= " AND nb_cheveaux  >= '$horse_nbr_min'";}else {$where .= "  nb_cheveaux  >= '$horse_nbr_min'";}}if ($horse_nbr_max) {
    if ($where ne '') {$where .= " AND nb_cheveaux  <= '$horse_nbr_max'";}else {$where .= "  nb_cheveaux  <= '$horse_nbr_max'";	} }
    if ($buy_price_min) {if ($where ne '') {$where .= " AND article.prix >= '$buy_price_min'";}else {$where .= "  article.prix >= '$buy_price_min'";}}
    if ($buy_price_max) {if ($where ne '') {$where .= " AND article.prix <= '$buy_price_max'";}else {$where .= "  article.prix <= '$buy_price_max'";}}
    if ($cyclindre_min) {if ($where ne '') {$where .= " AND article.nb_cylindre >= '$cyclindre_min'";}else {$where .= "  article.nb_cylindre >= '$cyclindre_min'";}}    
    if ($cyclindre_max) {if ($where ne '') {$where .= " AND article.nb_cylindre <= '$cyclindre_max'";}else {$where .= "  article.nb_cylindre <= '$cyclindre_max'";}}    
 if ($used) {
	        $from .= ",etat_libelle_langue";
	if ($where ne ''){
            $where .= " AND article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue, libelle, langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}else {
            $where .= " article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue, libelle, langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}
       } 
    my  $total = '0';
    my $add_where;
    if ($where eq '') {
	$add_where = "ref_statut = '3' AND article.ref_categorie = '5'";
    }else {
	$add_where = "AND ref_statut = '3' AND article.ref_categorie = '5'";
    }
    my  ($d)= $db->sqlSelect("count(id_article)", $from, $where ." $add_where");
    my  $nb_page = arrondi ($d / 40, 1);
    my  $min_index = '0';
    my  $max_index = '40';

    for (my  $i = '0'; $i < $nb_page;$i++) {
	my $n2 = $i %= 10;
	if ($n2 ne '0') {
		#$string .= "<br />";
	}
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=dosearchcar&amp;min_index=$min_index&amp;session=$session_id&fabricant=$fabricant&type=$type&year_fabrication_min=$year_fabrication_min&year_fabrication_max=$year_fabrication_max&km_min=$km_min&km_max=$km_max&horse_nbr_min=$horse_nbr_min&horse_nbr_max=$horse_nbr_max&price_min=$buy_price_min&price_max=$buy_price_max&withclim=$withclim&motorisation=$motorisation\"  class=\"menulink2\" ><-$i-></a>&#160;&nbsp;<img alt=\"\" alt=\"\" src=\"../images/next2.gif\" height=\"13px\" width=\"13px\">";		
	$min_index += 40;	
    }
    return $string;
}
#load search index result
sub doSearchCarIndexed {

    my $fabricant = $query->param("fabricant");
    $fabricant =~ s/[^\w ]//g;
    my $type = $query->param("subcategory");
    $type =~ s/[^\w ]//g;
    my $year_fabrication_min = $query->param("year_fabrication_min");
    $year_fabrication_min =~ s/[^\w ]//g;
    my $year_fabrication_max = $query->param("year_fabrication_max");
    $year_fabrication_max =~ s/[^\w ]//g;
    my $km_min = $query->param("km_min");
    $km_min  =~ s/[^\w ]//g;
    my $km_max = $query->param("km_max");
    $km_max  =~ s/[^\w ]//g;
    my $horse_nbr_min = $query->param ("horse_nbr_min");
    $horse_nbr_min  =~ s/[^\w ]//g;
    my $horse_nbr_max = $query->param ("horse_nbr_max");
    $horse_nbr_max  =~ s/[^\w ]//g;
    my $buy_price_min = $query->param ("price_min");
    $buy_price_min   =~ s/[^\w ]//g;
    my $cyclindre_min = $query->param ("cylindre_min");
    $cyclindre_min  =~ s/[^\w ]//g;
    my $cyclindre_max = $query->param ("cylindre_max");
    $cyclindre_max  =~ s/[^\w ]//g;
    my $buy_price_max = $query->param("price_max");
    $buy_price_max   =~ s/[^\w ]//g;
    my $withclim = $query->param("withclim");
    $withclim   =~ s/[^\w ]//g;
    my $motorisation = $query->param("motorisation");
    $motorisation  =~ s/[^\w ]//g;
    my $string;
    my $cl_value;
    my $used = $query->param("used");
    #$ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'price'},$ARTICLE{'image'},$ARTICLE{'fabricant'},$ARTICLE{'km'}
    my $select = "DISTINCT article.nom,id_article,prix,pochette,marque,nb_km";
        
    my  $from = "article";
    my  $where;

    if ($fabricant) {$where .= "article.marque = '$fabricant'";}
    if ($type) {
        if ($where ne '') {
	    $from .= ", subcategorie_libelle_langue";
            $where .= " AND article.ref_subcategorie = subcategorie_libelle_langue.ref_subcategorie AND subcategorie_libelle_langue = (SELECT libelle.libelle FROM subcategorie_libelle_langue, libelle, langue WHERE libelle.libelle = '$type' AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie.ref_langue = langue.id_langue AND langue.key = '$lang')";
            }
        else {
		$from .= ", subcategorie_libelle_langue";
                $where .= " article.ref_subcategorie = subcategorie_libelle_langue.ref_subcategorie AND subcategorie_libelle_langue.ref_subcategorie = (SELECT libelle.libelle FROM subcategorie_libelle_langue, libelle, langue WHERE libelle.libelle = '$type' AND subcategorie_libelle_langue.ref_libelle = libelle.id_libelle AND subcategorie.ref_langue = langue.id_langue AND langue.key = '$lang')";
                }
    }
    if ($year_fabrication_min) {if ($where ne '') {$where .= " AND article.annee >= '$year_fabrication_min'";}else {$where .= " article.annee >= '$year_fabrication_min'";}}
    if ($year_fabrication_max) {if ($where ne '') {$where .= " AND article.annee <= '$year_fabrication_min'";}else {$where .= " article.annee <= '$year_fabrication_min'";}}
    if ($motorisation and $motorisation ne '') {if ($where ne '') {$where .= " AND article.essence_ou_diesel = id_type_essence AND type_essence_$lang.nom = '$motorisation'";}else {$where .= " article.essence_ou_diesel  = id_type_essence AND type_essence_$lang.nom = '$motorisation'";}$from .= ",type_essence_$lang";}
    if ($km_min) {if ($where ne '') {$where .= "AND article.nb_km >= '$km_min'";}else {$where .= " article.nb_km >= '$km_min'";}}
    if ($withclim and $withclim ne '---------') {if ($withclim eq 'Yes' or $withclim eq 'Oui' or $withclim eq 'Ya') {$cl_value = 1;}else {$cl_value = 0;}if ($where ne '') {$where .= " AND article.clima = '$cl_value'";}else {$where .= " article.clima = '$cl_value'";}}
    if ($km_max) {if ($where ne '') {$where .= "AND article.nb_km <= '$km_max'";}else {$where .= " article.nb_km <= '$km_max'";}}    
    if ($horse_nbr_min) {if ($where ne '') {$where .= " AND nb_cheveaux  >= '$horse_nbr_min'";}else {$where .= "  nb_cheveaux  >= '$horse_nbr_min'";}}if ($horse_nbr_max) {
    if ($where ne '') {$where .= " AND nb_cheveaux  <= '$horse_nbr_max'";}else {$where .= "  nb_cheveaux  <= '$horse_nbr_max'";	} }
    if ($buy_price_min) {if ($where ne '') {$where .= " AND article.prix >= '$buy_price_min'";}else {$where .= "  article.prix >= '$buy_price_min'";}}
    if ($buy_price_max) {if ($where ne '') {$where .= " AND article.prix <= '$buy_price_max'";}else {$where .= "  article.prix <= '$buy_price_max'";}}
    if ($cyclindre_min) {if ($where ne '') {$where .= " AND article.nb_cylindre >= '$cyclindre_min'";}else {$where .= "  article.nb_cylindre >= '$cyclindre_min'";}}    
    if ($cyclindre_max) {if ($where ne '') {$where .= " AND article.nb_cylindre <= '$cyclindre_max'";}else {$where .= "  article.nb_cylindre <= '$cyclindre_max'";}}    
    if ($used) {
	        $from .= ",etat_libelle_langue";
	if ($where ne ''){
            $where .= " AND article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue, libelle, langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}else {
            $where .= " article.ref_etat = etat_libelle_langue.ref_etat AND etat_libelle_langue.ref_etat = (SELECT ref_etat FROM etat_libelle_langue, libelle, langue WHERE libelle.libelle = '$used' AND etat_libelle_langue.ref_libelle = libelle.id_libelle AND etat_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang')";
	}
       } 

    my  $add_where;
    if ($where eq '') {	$add_where = "ref_statut = '3' AND article.ref_categorie = '5'"; }else {$add_where = "AND ref_statut = '3' AND article.ref_categorie = '5'";}
    my  $index_start = $query->param ("min_index") ;
    $index_start=~ s/[^A-Za-z0-9 ]//;
    my  $index_end = $query->param ("max_index") ;
    $index_end=~ s/[^A-Za-z0-9 ]//;
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d",$year+1900,$mon+1,$mday;    
    if (!$index_start ) {$index_start = 0;}
    if (!$index_end ) {$index_end = 40;}

    my  $total = '0';
    
    my  ($d)= $db->sqlSelectMany($select, $from, $where ." $add_where LIMIT $index_start, $index_end");

    $string = "<table style=\"border-width:thin; border-style:dotted;border-top-color:#94CEFA;border-right-color:#94CEFA;border-left-color:#94CEFA; border-right-width:2px; border-bottom-color:#94CEFA\" width=\"555\" border=\"0\"><tr bgcolor=\"#DBE4F8\"><td align=\"left\" width=\"51\">$SERVER{'image'}</td><td align=\"left\">Nom</td><td align=\"left\">$SERVER{'fabricant'}</td><td align=\"left\">$SERVER{'article_price_label'}</td><td align=\"left\">Km</td></tr>";
    while( ($ARTICLE{'name'},$ARTICLE{'id_article'},$ARTICLE{'price'},$ARTICLE{'image'},$ARTICLE{'fabricant'},$ARTICLE{'km'})=$d->fetchrow()) {
	$string .= "<tr><td align=\"left\"><img alt=\"\" alt=\"\" src=\"$ARTICLE{'image'}\"></td><td align=\"left\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=detailother&amp;article=$ARTICLE{'id_article'}&amp;$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'fabricant'}</td><td align=\"left\">$ARTICLE{'price'}</td><td align=\"left\">$ARTICLE{'km'}</td></tr>";
    }
    $string .="</table>";    
    return $string;
}

sub doSearch_vinyl {
    my  $article = shift || '';
    my  $article_genre = shift || '';
    my  $artist = shift || '';
    my  $depot = $query->param("depot");
    $depot =~ s/[^\w ]//g;
    my  $string = "";
    my  $select = "DISTINCT article.nom";
    my  $from = "article, met_en_vente,genre,depot,statut_libelle_langue";
    my  $where;

   
    if ($article ne '' & $article_genre ne '' & $artist ne '') {
	$where = "article.nom LIKE '%$article%' AND genre = LIKE '%$article_genre%' AND marque LIKE '%$artist%'";
    } elsif ($article ne '' & $article_genre ne '' & $artist eq '') {
	$where = "article.nom LIKE '%$article%' AND genre LIKE '%$article_genre%'";
    } elsif ($article ne '' & $artist ne '' & $artist eq '') {
	$where = "article.nom LIKE '%$article%' AND marque LIKE '%$artist%'";
    } elsif ($article_genre ne '' & $artist ne '' & $article_genre eq '') {
	$where = "genre LIKE '%$article_genre%' AND marque LIKE '%$artist%'";
    } elsif ($article ne '' & $artist eq '' & $article_genre eq '') {
	$where = "article.nom LIKE '%$article%'";
    } elsif ($article_genre ne '' & $artist eq '' & $article eq '') {
	$where = "genre LIKE '%$article_genre%'";
    } elsif ($article_genre eq '' & $artist ne '' & $article eq '') {
	$where = "marque LIKE '%$artist%'";
    }
    if ($depot) {
	$where = " depot.ville = '$depot'";
    }

    my  $total = '0';
    
    my  ($d)= sqlSelect("count(id_article)", $from, $where . " AND id_article = ref_article AND ref_genre = id_genre AND ref_depot = id_depot AND article.ref_statut = statut_libelle_langue.ref_statut AND statut_libelle_langue.ref_statut = '3' AND statut_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my  $nb_page = arrondi ($d / 40, 1);
    my  $min_index = '0';
    my  $max_index = '40';

    for (my  $i = '0'; $i < $nb_page;$i++) {
	my $n2 = $i %= 10;
	if ($n2 ne '0') {
		#$string .= "<br />";
	}
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=search&amp;min_index=$min_index&amp;search_name=$article&amp;search_genre=$article_genre&amp;search_artist=$artist&session=$session_id\"  class=\"menulink2\" ><-$i-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }
    return $string;
}
#load search index result
sub doSearchIndexed_vinyl {
    my  $article = shift || '';
    my  $article_genre = shift || '';
    my  $artist = shift || '';
    my  $depot = $query->param("depot");
    $depot =~ s/[^A-Za-z0-9 ]//;
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
    my  $select = "DISTINCT article.nom,marque,label,prix, genre,depot.ville";
    my  $from = "article, met_en_vente,genre,depot,statut_libelle_langue";

    my  $where;
    my  $string = "<table width=\"305\" border=\"0\"><tr bgcolor=\"#DBE4F8\"><td align=\"left\" width=\"51\">$SERVER{'article_name_label'}</td><td align=\"left\">$SERVER{'article_author_label'}</td><td align=\"left\">$SERVER{'article_label_label'}</td><td align=\"left\">$SERVER{'article_price_label'}</td><td align=\"left\">$SERVER{'article_genre'}</td><td align=\"left\">$SERVER{'depot'}</td></tr>";
    
    if ($article ne '' & $article_genre ne '' & $artist ne '') {
	$where = "article.nom LIKE '%$article%' AND genre = LIKE '%$article_genre%' AND marque LIKE '%$artist%'";
    } elsif ($article ne '' & $article_genre ne '' & $artist eq '') {
	$where = "article.nom LIKE '%$article%' AND genre LIKE '%$article_genre%'";
    } elsif ($article ne '' & $artist ne '' & $artist eq '') {
	$where = "article.nom LIKE '%$article%' AND marque LIKE '%$artist%'";
    } elsif ($article_genre ne '' & $artist ne '' & $article_genre eq '') {
	$where = "genre LIKE '%$article_genre%' AND marque LIKE '%$artist%'";
    } elsif ($article ne '' & $artist eq '' & $article_genre eq '') {
	$where = "article.nom LIKE '%$article%'";
    } elsif ($article_genre ne '' & $artist eq '' & $article eq '') {
	$where = "genre LIKE '%$article_genre%'";
    } elsif ($article_genre eq '' & $artist ne '' & $article eq '') {
	$where = "marque LIKE '%$artist%'";
    }
        if ($depot) {
	$where = " depot.ville = '$depot'";
    }

    my  ($c)= sqlSelectMany($select, $from, $where . "AND id_article = ref_article AND ref_genre = id_genre AND ref_depot = id_depot AND article.ref_statut = statut_libelle_langue.ref_statut AND statut_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' AND statut_libelle_langue.ref_statut = '3' LIMIT $index_start, $index_end");

    while( ($ARTICLE{'name'},$ARTICLE{'author'},$ARTICLE{'label'},$ARTICLE{'price'},$ARTICLE{'genre'},$ARTICLE{'depot'})=$c->fetchrow()) {
	$string .= "<tr><td align=\"left\"><a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;action=detail&amp;article=$ARTICLE{'name'}&session=$session_id\" class=\"menulink\" >$ARTICLE{'name'}</a></td><td align=\"left\">$ARTICLE{'author'}</td><td align=\"left\">$ARTICLE{'label'}</td><td align=\"left\">$ARTICLE{'price'}</td><td align=\"left\">$ARTICLE{'genre'}</td><td align=\"left\">$ARTICLE{'depot'}</td></tr>";
    }
    $string .="</table>";    
    return $string;
}

BEGIN {
    use Exporter ();
  
    @Search::ISA = qw(Exporter);
    @Search::EXPORT      = qw(new doSearchIndexed_vinyl doSearch_vinyl doSearchCarIndexed doSearchCar searchCar doSearchMotoIndexed doSearchMoto searchMoto doSearchTvIndexed  doSearchTv doSearchInfoIndexed doSearchInfo  searchInfo2 searchTv doSearchLingerieIndexed doSearchLingerie doSearchWearIndexed  doSearchWear doSearchAnimalIndexed doSearchAnimal  searchAnimal searchLingerie doSearchInstrumentsIndexed doSearchInstruments searchInstruments searchInfo  searchWear doSearchCigaresIndexed doSearchCigares searchCigares doSearchJardinIndexed doSearchJardin doSearchArtIndexed doSearchArt doSearchWatchIndexed doSearchWatch searchJardin searchArt doSearchParfumIndexed doSearchParfum searchParfum searchWatch doSearchIndexed doSearch doSearchIndexed_vinyl doSearchVinyl searchVinyl);
    @Search::EXPORT_OK   = qw();
}
1;
