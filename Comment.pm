package Comment;
use warnings;
use CGI;
use Time::HiRes qw(gettimeofday);
use Article;
use DBI;
use MyDB;
use LoadProperties;
use ImageManipulation;

use vars qw (%ENV $session_dir $can_do_gzip $cookie $page $dir $dirLang $dirError $imgdir $action $t0 $session_id $ycan_do_gzip $current_ip $lang $LANG %ARTICLE %SESSION %SERVER %USER $CGISESSID %LABEL %ERROR %VALUE $COMMANDID %COMMAND %DATE %PAYPALL $INDEX %LINK  $query $session $host $t0  $client);
$query = CGI->new ;
$cookie = "";
$current_ip = $ENV{'REMOTE_ADDR'};
$client = $ENV{'HTTP_USER_AGENT'};
$t0 = gettimeofday();
$host = "http://127.0.0.1";
%ERROR = ();%LABEL = ();$LANG = "";%LINK = ();%ARTICLE = ();%SESSION = ();
my %SERVER = ();
my $the_key = "otherbla";
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

my $dsn = "DBI:mysql:recordz";
my $username = "root";
my $password = '';
my $mydb = MyDB->new;
my $query = CGI->new ;
my $tableArticle = TableArticle->new;
my $articleClass = Article->createArticle();
my $imageManipulation = ImageManipulation->new;
my $userAction;
my $lang;
my $db = MyDB->new();
my $lp = LoadProperties->create();

sub viewCommentIndex {
    my $lang = query->param("lang");
    my $username = $query->param("username");
    my  ($c)= $db->sqlSelect("count(commentaire.id_commentaire)",
			   "commentaire,personne",
			   "commentaire.ref_emetteur = (SELECT id_personne FROM personne WHERE nom_utilisateur = '$username')");	
	

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
	$string .= "<a href=\"/cgi-bin/recordz.cgi?page=main&lang=$lang&amp;session=$session_id&amp;min_index_comments=$min_index&amp;max_index_comments=$max_index&amp;country_swiss=$country_swiss&amp;country_france=$country_france&amp;with_lang_french=$with_lang_french&amp;with_lang_german=$with_lang_german&amp;with_lang_italian=$with_lang_italian&amp;with_lang_english=$with_lang_english&saw=lasthour\"  class=\"menulink2\" ><-$j-></a>&#160;&nbsp;";		
	$min_index += 4;	
    }
    if ($nb_page % 10 > 0) {
	$string .= "<br/>";
    }        
return $string;    
    
}
sub viewCommentTable {
    my $lang = query->param("lang");
    my $username = $query->param("username");
    my $min_index_comments = $query->param("min_index_comments");
    my $max_index_comments = $query->param("max_index_comments");
        my $article = $query->param("article");
    my  $cat = shift || '';
    my  $type = shift  || '';
    my  $depot = $query->param("depot") ;
    $depot=~ s/[^A-Za-z0-9 ]//;
    
    
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
		        "commentaire, personne, article",
		       "ref_article = id_article and ref_emetteur = id_personne AND ref_emetteur = SELECT (id_personne) FROM personne WHERE nom_utilisateur = '$username' LIMIT $min_index_comments, $max_index_comments");	
    

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
BEGIN {
    use Exporter ();
  
    @Comment::ISA = qw(Exporter);
    @Comment::EXPORT  = qw();
    @Comment::EXPORT_OK   =  qw (viewCommentTable () viewCommentIndex());  
  }
1;

