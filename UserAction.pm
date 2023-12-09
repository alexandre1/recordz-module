package UserAction;
use warnings;
my $method='POST';
use HTTP::Request::Common;
use LWP;
use MyDB;
use SharedVariable;
use Time::HiRes qw(gettimeofday);
#use Search;
use Article;
use LoadPage;
use Digest::MD5 qw(md5_hex);
use Sys::Hostname;
use vars qw (%ENV $session_dir $can_do_gzip $cookie $page $dir $dirLang $dirError $imgdir $action $t0 $session_id $ycan_do_gzip $current_ip $lang $LANG %ARTICLE %SESSION %SERVER %USER $CGISESSID %LABEL %ERROR %VALUE $COMMANDID %COMMAND %DATE %PAYPALL $INDEX %LINK  $query $session $host $t0  $client);
our $loadPage = LoadPage->new;
our $lp = LoadProperties->create();
our $articleClass = Article->createArticle();
our $db = MyDB->new;
our $the_key = "otherbla";

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

my $dsn = "DBI:mysql:recordz";
my $username = "root";
my $password = '';
my $mydb = MyDB->new;
my $query = CGI->new ;
my $tableArticle = TableArticle->new;
my $articleClass = Article->createArticle();
my $lang;

loadLanguage();
loadError();

sub insertCommentaire {
	my $article = $query->param("article");
	my  $session = new CGI::Session( "driver:File", $session_id,  {Directory=>"$session_dir"} ); 
	my $question = $query->param("text");
	my $text = $query->param("editor1");
    my $username = $query->param("user_name");
    my $password = $query->param("user_password");
    my  ($id_personne, $nom_utilisateur,$username_password)=$db->sqlSelect("id_personne, nom_utilisateur", "personne",	
    			       "nom_utilisateur = '$username' AND mot_de_passe = '$password'");
    if ($id_personne ne "") {
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
	my  $date = sprintf "%4d-%02d-%02d",$year+1900,$mon+1,$mday;
	my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
	$db->sqlInsert("commentaire",
		  ref_article   => "$article", 		      
		  question      => "$question",
		  texte          => "$text",
		  ref_emetteur  => "$id_personne",   
		  date  	    => "$date $time");
	
	    $loadPage->detailOther();
    } else {
	print "Content-Type: text/html\n\n";
	print "<link href=\"/css/main.css\" rel=\"stylesheet\" type=\"text/css\" />";
	print "$ERROR{'password_wrong'}";
	print "<br/>";
	print "<br/>";
	print "<input type=\"button\" name=\"close\" value=\"Fermer\" onClick=\"window.close(); \"</input>";
	print "&nbsp;&nbsp;";
	print "<input type=\"button\" name=\"back\" value=\"Retour\" onClick=\"window.history.back(1); \"</input>";
    }	
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
		$lang = uc ($lang);
		open (FILE, "<$dirLang/$lang.conf") or die "cannot open file $dirLang/$lang.conf";    
		
		while (<FILE>) {
		(my  $label, my  $value) = split(/=/);
		$SERVER{$label} = $value;
		}
		close (FILE);
	}
}


sub registerPriceNext {
    my $string;
    my $account = $query->param("account_type");
    my $selected = $query->param("time");  
    my  ($c)= sqlSelect("prix","type_de_compte_libelle_langue,libelle,langue","type_de_compte_libelle_langue.ref_libelle = libelle.id_libelle AND libelle.libelle = '$account' AND type_de_compte_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my $x = $c * $selected;
    $x =~ s/\[0-9]//g; ;
    my $s = "$x";
    return $s;
}

sub _untaint { # This doesn't make things safe. It just removes the taint flag. Use wisely.
   my ($value) = @_;
   my ($untainted_value) = $value =~ m/^(.*)$/s;
   return $untainted_value;
}

sub registerNewUser {
    my  $user_name = $query->param ('user_name');    
    my  $first_name = $query->param ('first_name');
    my  $name = $query->param ('name');
    my  $user_password = $query->param ('user_password') ;
    
    my  $country = $query->param ('country_name') ;
    my  $adress= $query->param ('adress_name');
    my  $city= $query->param ('city') ;
    my  $npa = $query->param ('npa') ;
    my  $phone_number= $query->param ('phone_number');
    my  $email= $query->param ('email');
    my  $account_type = $query->param("account_type");
    my  $msn = $query->param("msn_messenger");
    my  $skype = $query->param("skype");
    my  $iban = $query->param("iban");
    my  $time = $query->param('type');
    my  $price = $query->param("price");
    my  $d = $query->param('type');
   #vérifier la correspondance entre le password et le verify sinon erreur
    my  $verify = $query->param('login_password_verify_label');
    
    my $error = '0';
    loadError();
    if ($email eq '') {
	$ERROR{'email_error_label'} = $ERROR{'email_label'};
	$error = '1';
    } else {
    	$ERROR{'email_error_label'} = '';
    }
    if ($user_password eq '') {
	$ERROR{'user_password_null'} = $ERROR{'user_password_null'}; $error = '1';
	}
    else {
	$ERROR{'user_password_null'} = '';
	}
    if ($verify ne $user_password) {$ERROR{'user_password_not_match'} = $ERROR{'user_password_not_match'}; $error = 1;} else {$ERROR{'user_password_not_match'} = '';}
    if ($user_name eq '') {
	$ERROR{'username_label_error'} .= $ERROR{'username_label_error'};
	$error = '1';
	}
    else {
	$ERROR{'username_label_error'} =  '';
    };
    if ($first_name eq '') {$ERROR{'first_name_error'} = $ERROR{'first_name_error'}; $error = '1';} else {$ERROR{'first_name_error'} = '';};
    if ($name eq '') {$ERROR{'name_error_label'} = $ERROR{'name_error_label'}; $error = '1';} else {$ERROR{'name_error_label'} = '';};
    if ($npa eq '') {$ERROR{'npa_error_label'} = $ERROR{'npa_error_label'}; $error = '1';} else {$ERROR{'npa_error_label'} = '';};
    if ($adress eq '') {$ERROR{'adress_error_label'} = $ERROR{'adress_error_label'}; $error = '1';} else {$ERROR{'adress_error_label'} = '';};
    if ($city eq '') {
	$ERROR{'city_error_label'} = $ERROR{'city_error_label'};
	$error = '1';
	} else {
	$ERROR{'city_error_label'} = '';
	};
    if ($phone_number  eq '') {
	$ERROR{'phone_number_label'} = $ERROR{'phone_number_label'};
	$error = '1';
	} else {$ERROR{'phone_number_label'} = '';
    };
    

    my $l = $query->param("lang");
    my  ($email_from_db)=$db->sqlSelect("email", "personne",	
    			       "email = '$email'");
    if ($email_from_db eq '' and $email ne '') {
	$ERROR{'email_error_label'} = '';
    }
    if ($email_from_db ne '') {
	$error = 1;
	$ERROR{'email_error_label'} = $ERROR{'email_label'};
    }
    
    if ($email eq '' and $l eq 'FR') {
	$ERROR{'email_error_label'} = $ERROR{'email_label'};
	$error = 1;
    }
    
    my  ($nom_utilisateur)=$db->sqlSelect("nom_utilisateur", "personne",	
    			       "nom_utilisateur = '$user_name'");
  
    if ($nom_utilisateur ne '') {
	$ERROR{'username_label_error'} .= "Le nom d'utilisateur est déjà pris"; $error = '1';
	
    } 


    if ($nom_utilisateur eq '' and $error eq '0' and $email_from_db eq '') {

	    $ERROR{'email_error_label'} = '';
	    my  ($account_type_id)=$db->sqlSelect("ref_type_de_compte", "type_de_compte_libelle_langue, libelle, langue",
					   "type_de_compte_libelle_langue.ref_libelle = libelle.id_libelle AND type_de_compte_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang' AND libelle.libelle = '$account_type'");
    
		$db->sqlInsert("personne",
			nom_utilisateur		=> $user_name,
			mot_de_passe		=> $user_password,	    
			nom			=> $name,
			prenom			=> $first_name,
			adresse			=> $adress,
			npa	  		=> $npa,
			ville			=> $city,
			pays			=> $country,
			no_telephone		=> $phone_number,
			email			=> $email,
			active			=> '0',
			level			=> '1',			
			msn_messenger		=> $msn,
			iban 			=> $iban,
			skype_name 		=> $skype
		);
    
	    my  ($id_personne)=$db->sqlSelect("id_personne", "personne",
					   "nom_utilisateur = '$user_name'");
		$loadPage->loadLogin();
	}else {
	    open (FILE, "<$dir/register_error.html") or die "cannot open file $dir/register_error.html";
	    my $content;my $s = loadRegisterCategories();
	    my $string2 = getCountry();
	    my $cats = $articleClass->getCat();
	    $ARTICLE{'image_pub'} = $loadPage->loadPublicite ();
            my $categories_account = $lp->loadRegisterTypeAccount();
            my $countries = $lp->loadRegisterCountry();
	    #my $time = $lp->loadRegisterTime();
	    #my $price = $lp->loadRegisterPrice();
	    my $menu = $lp->loadMenu();
	    while (<FILE>) {
		s/\$LABEL{'([\w]+)'}/ exists $SERVER{$1} ? $SERVER{$1} : $1 /eg; 
		s/\$LANG/$lang/g;
		s/\$COUNTRY/$string2/g;
		s/\$OPTIONS{'categories'}/$cats/g;
		s/\$SELECT{'categories_account'}/$s/g;
		s/\$ARTICLE{'main_menu'}/$menu/g;
		s/\$ERROR{'username_label_error'}/$ERROR{'username_label_error'}/g;
		s/\$ERROR{'login_error_label'}/$ERROR{'login_error_label'}/g;    	
		s/\$ERROR{'first_name_error'}/$ERROR{'first_name_error'}/g;
		s/\$ERROR{'name_error_label'}/$ERROR{'name_error_label'}/g;
		s/\$ERROR{'npa_error_label'}/$ERROR{'npa_error_label'}/g; 
		s/\$ERROR{'adress_error_label'}/$ERROR{'adress_error_label'}/g;
		s/\$ERROR{'city_error_label'}/$ERROR{'city_error_label'}/g;
		s/\$ERROR{'phone_number_label'}/$ERROR{'phone_number_label'}/g;
		s/\$ERROR{'email_error_label'}/$ERROR{'email_error_label'}/g;
		s/\$ERROR{'user_password_null'}/$ERROR{'user_password_null'}/g;
		s/\$ERROR{'user_password_not_match'}/$ERROR{'user_password_not_match'}/g;
		s/\$SELECT{'time'}/$time/g;
		s/\$SELECT{'price'}/$price/g;
		s/\$ARTICLE{'account_type'}/$account_type/g;
		s/\$SELECT{'time'}/$time/g;
		s/\$SELECT{'price'}/$price/g;
		s/\$ARTICLE{'user_name'}/$user_name/g;
		s/\$ARTICLE{'first_name'}/$first_name/g;
		s/\$ARTICLE{'name'}/$name/g;
		s/\$ARTICLE{'country_name'}/$country/g;
		s/\$ARTICLE{'adress_name'}/$adress/g;
  	        s/\$ACCOUNT_TYPE/$categories_account/g;
	        s/\$ARTICLE{'country'}/$countries/g;
	        s/\$SELECT{'time'}/$time/g;		
		s/\$ARTICLE{'city'}/$city/g;
		s/\$ARTICLE{'npa'}/$npa/g;
		s/\$ARTICLE{'iban'}/$iban/g;
		s/\$ARTICLE{'phone_number'}/$phone_number/g;
		s/\$ARTICLE{'email'}/$email/g;
		s/\$ARTICLE{'msn_messenger'}/$msn/g;
		s/\$ARTICLE{'skype'}/$skype/g;		
		s/\$COUNTRY/$string2/g;
		s/\$ARTICLE{'image_pub'}/$ARTICLE{'image_pub'}/g;
		s/\$ARTICLE{'main_menu'}/$menu/g;
		s/\$SESSIONID/$session_id/g;
		$content .= $_;	
	    }
		print "Content-Type: text/html\n\n"; 
		print $content;
		close (FILE);
    }
  
}
sub getCountry {
    my $selected = $query->param("country_name");
    my  ($c)= $db->sqlSelectMany("nom",
			   "pays_present",
			   "id_pays_present = id_pays_present");	
	my  $string = "";
	my  %COUNTRY = ();
	$string .= "<select name =\"country_name\">";
	if ($selected) {
	    $string .= "<option selected VALUE=\"$selected\">$selected<option>";
	}
	while(($COUNTRY{'name'})=$c->fetchrow()) {

		$string .= "<option VALUE=\"$COUNTRY{'name'}\">$COUNTRY{'name'}</option>";

	}
    $string .= "</select>";
    return $string;
}
sub sendNewRegistrationMailAndSms {
    my  $email = shift || '';
    my  $username = shift || '';
    my  $password = shift || '';
    my  $user_name = shift || '';
    my  $first_name = shift || '';
        
    my  $Message = new MIME::Lite From =>'robot@djmarketplace.biz',
		    To =>$email, Subject =>$SERVER{'msg_subscription_title'} ,
		    Type =>'TEXT',
		    Data =>"$SERVER{'msg_subscription_content'} <a href=http://djmarketplace.no-ip.biz/cgi-bin/recordz.cgi?action=confirmation&userID=$username&lang=$lang&amp;session=$session_id>$SERVER{'msg_subscription_url_msg'}</a><br><br>$SERVER{'login_username_label'} : $username<br><br>$SERVER{'login_password_label'}: $password";       
    $Message->attr("content-type" => "text/html; charset=iso-8859-1");
    $Message->send_by_smtp('localhost:25');    
}

sub confirmRegistration {
    my  $username = $query->param ('userID');
    $username = s/[^\w ]//g;  
    sqlUpdate("personne", "nom_utilisateur='$username'",(active => '1'));    
    open (FILE, "<$dir/main.html") or die "cannot open file $dir/main.html";
    my $content;
    my  $string = loadArticleNews();
    my $menu = loadMenu();
    my $cats = getCat();
	while (<FILE>) {
	    s/\$LABEL{'([\w]+)'}/ exists $SERVER{$1} ? $SERVER{$1} : $1 /eg;  s/\$ARTICLE{'main_menu'}/$menu/g;
	    s/\$LANG/$lang/g;s/\$OPTIONS{'categories'}/$cats/g;
  	    s/\$ARTICLE{'news'}/$string/g;s/\$ARTICLE{'search'}//g;
	    $content .= $_;	
    }
	$content = Compress::Zlib::memGzip($content)  if $can_do_gzip; ;
	print "Content-Length: ", length($content) , "\n";
	print "Content-Encoding: gzip\n" ;
	print "Content-Type: text/html\n\n"; 
	print $content;
        close (FILE);    
}

sub loadRegisterCategories {
    my $string;
    my  ($c)= $db->sqlSelectMany("libelle.libelle","type_de_compte_libelle_langue,libelle,langue","type_de_compte_libelle_langue.ref_libelle = libelle.id_libelle AND type_de_compte_libelle_langue.ref_langue = langue.id_langue AND langue.key = '$lang'");
    my $s = "<select name=\"account_type\" onchange=\"go();\">";
    my  %OPTIONS = ();
    my $selected = $query->param("account-type");
    $s .= "<option selected VALUE=\"$selected\">$selected</option>";
    while(($OPTIONS{'category'})=$c->fetchrow()) {	
         $s.= "<option value=\"/cgi-bin/recordz.cgi?lang=$lang&page=register&session=$session_id&account_type=$OPTIONS{'category'}\">$OPTIONS{'category'}</option>";
	}
	$s	 .= "</select>";
    return $s;
}
#send back account information to user
sub forgetPassword {
    my  $email = $query->param('email');    
    #$email=~ s/[^A-Za-z0-9 ]//;    
    my  $string1= "";
    my  $string2= "";
    $session = new CGI::Session("driver:File", $session_id, {Directory=>"$session_dir"});
    my  ($username,$password)=sqlSelect("nom_utilisateur , mot_de_passe", "personne",
				       "email = '$email'");
    my $level = $session->param("level");  
    if ($username && $password) {
	my $string3 = getSelectArticleDepot();
	my  $Message = new MIME::Lite From =>'robot@djmarketplace.biz',
			To =>$email, Subject =>$SERVER{'msg_subscription_title'} ,
			Type =>'TEXT',
			Data =>"$SERVER{'msg_recovery'}<br><br>$SERVER{'login_username_label'} : $username<br><br>$SERVER{'login_password_label'}: $password";       
	$Message->attr("content-type" => "text/html; charset=iso-8859-1");
	$Message->send_by_smtp('localhost:25');	
	open (FILE, "<$dir/login.html") or die "cannot open file $dir/login.html";
	my $content;
	my  $string = loadArticleNews();
	$string1 = loadArticleNews();
	$string2 = loadViewArticleNewsByIndex();
	my $cats = getCat();
	my $menu = loadMenu();
	while (<FILE>) {	
	    s/\$LABEL{'([\w]+)'}/ exists $SERVER{$1} ? $SERVER{$1} : $1 /eg; 
	    s/\$LANG/$lang/g;
	    s/\$OPTIONS{'categories'}/$cats/g;
	    s/\$ERROR{'email_error_label'}//g;
	    s/\$ERROR{'login_error_label'}/$SERVER{'pass_sent'}/g;
	    s/\$ARTICLE{'main_menu'}/$menu/g;
	    s/\$ARTICLE{'index_table'}/$string1/g;
	    s/\$ARTICLE{'news'}/$string2/g;
	    s/\$SELECT{'depot'}/$string3/g;
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
    else {
	open (FILE, "<$dir/login.html") or die "cannot open file $dir/login.html";
	my $content;
	my $menu = loadMenu();
	my $cats = getCat();
	while (<FILE>) {	
	    s/\$LABEL{'([\w]+)'}/ exists $SERVER{$1} ? $SERVER{$1} : $1 /eg; 
	    s/\$LANG/$lang/g;
	    s/\$OPTIONS{'categories'}/$cats/g;
	    s/\$ERROR{'login_error_label'}//g;
	    s/\$ARTICLE{'main_menu'}/$menu/g;
	    s/\$ERROR{'email_error_label'}/$SERVER{'email_error_label'}/;
	    $content .= $_;	
	}
	$content = Compress::Zlib::memGzip($content)  if $can_do_gzip; ;
	print "Content-Length: ", length($content) , "\n";
	print "Content-Encoding: gzip\n" ;
	print "Content-Type: text/html\n\n"; 
	print $content;
	close (FILE);	
    }        
}


sub payedSuccess {
	my $article = $query->param("article");
	my $id_a_livre = $query->param("id_a_livre");
	my $buyer = $query->param("buyer");
	
	my $note = $query->param("note");
	my  $session = new CGI::Session( "driver:File", $session_id,  {Directory=>"$session_dir"} );
	my $username = $session->param("username");
	if ($username) {
		my  ($userID) = sqlSelect("id_personne", "personne", "nom_utilisateur = '$username'");		
		my  ($isenchere) = sqlSelect("enchere", "article", "id_article = '$isenchere'");
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
				my $condition;
				($condition) = sqlSelect("ref_condition_livraison", "article", "id_article = $article");
				sqlUpdate("a_livre", "id_a_livre=$id_a_livre",(ref_statut => "14", ref_mode_livraison => $condition));
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



#update user account

sub updatePersonalData {
    my  $registration_news = $query->param('register_newsletter');
    #$registration_news=~ s/[^A-Za-z0-9 ]//;
    my  $first_name = $query->param ('first_name');
    
    my  $user_name = $query->param ('name') ;
    
    my  $user_password = $query->param ('user_password');
    #$user_password= s/[^\w ]//g;  
    my  $country = $query->param ('country_name');
    
    my  $adress= $query->param ('adress_name');
    
    my  $city= $query->param ('city');
    
    my  $npa = $query->param ('npa');
    
    my  $phone_number= $query->param ('phone_number');
    #$phone_number= s/[^\w ]//g;  
    my  $email= $query->param ('email') ;
     #$CGI::Session::MySQL::TABLE_NAME = 'sessions';
     $session = new CGI::Session("driver:File", $session_id, {Directory=>"$session_dir"});
     #print $session->header();
     my  $username = $session->param("username"); 
    if ($username) {

	if ($first_name &
	    $user_name &
	    $user_password  &
	    $country  &
	    $adress  &
	    $city  &
	    $npa  &
	    $phone_number &
	    $email) {
	    
	    sqlUpdate("personne","nom_utilisateur='$username'",(
		    mot_de_passe		=> $user_password,	    
		    nom				=> $user_name,
		    prenom			=> $first_name,
		    adresse			=> $adress,
		    npa	  			=> $npa,
		    ville			=> $city,
		    pays			=> $country,
		    no_telephone		=> $phone_number,
		    email			=> $email)
	    );    
	    loadPage();
	}
	else {
	    
	    my $content;
	    open (FILE, "<$dir/personal_data.html") or die "cannot open file $dir/personal_data.html";
	    my  $string = "Tous les champs doivent être rempli";	
	    ($VALUE{'first_name'},$VALUE{'name_per'},
	     $VALUE{'adress_name'}, $VALUE{'city'},
	     $VALUE{'npa'}, $VALUE{'phone_number'},
	     $VALUE{'email'})= sqlSelect("prenom, nom,adresse,ville, npa, no_telephone, email",
					 "personne","nom_utilisateur = '$username'");	
	    open (FILE, "<$dir/personal_data.html") or die "cannot open file $dir/personal_data.html";
	    my $menu = loadMenu();
	    my $cats = getCat();
	    while (<FILE>) {
		s/\$LABEL{'([\w]+)'}/ exists $SERVER{$1} ? $SERVER{$1} : $1 /eg; 
		s/\$VALUE{'first_name'}/$VALUE{'first_name'}/g;
		s/\$VALUE{'name_per'}/$VALUE{'name_per'}/g;
		s/\$OPTIONS{'categories'}/$cats/g;
		s/\$ARTICLE{'main_menu'}/$menu/g;	    
		s/\$VALUE{'adress_name'}/$VALUE{'adress_name'}/g;
		s/\$VALUE{'city'}/$VALUE{'city'}/g;
		s/\$VALUE{'npa'}/$VALUE{'npa'}/g;
		s/\$VALUE{'phone_number'}/$VALUE{'phone_number'}/g;
		s/\$VALUE{'email'}/$VALUE{'email'}/g;
		s/\$LANG/$lang/g;
		s/\$ERROR{'all_label'}/$string/g;
		s/\$SESSIONID/$CGISESSID/g;
		s/\$ARTICLE{'search'}//g;	    
		$content .= $_;	
	    }
		$content = Compress::Zlib::memGzip($content)  if $can_do_gzip; ;
		print "Content-Length: ", length($content) , "\n";
		print "Content-Encoding: gzip\n" ;
		print "Content-Type: text/html\n\n"; 
		print $content;	    
	        close (FILE);    
	}
    } else {
	login();
    }
}
sub acheter {
	my $article  = $query->param("article");
	my $username = $query->param("username");
	my $password = $query->param("password");
	my $quantite = $query->param("quantity_wanted");
	my $mode_livraison_ref = $query->param("mode_livraison_ref");
	my $mode_payement_ref = $query->param("mode_payement_ref");
	my  ($user_name,$user_password)= ();
	 ($user_name,$user_password)=$db->sqlSelect("nom_utilisateur , mot_de_passe",
					     "personne", "nom_utilisateur = '$username' AND mot_de_passe='$password'");
    
	
	
	if ($user_name && $user_password) {
		my ($userID)=$db->sqlSelect("id_personne", "personne", "nom_utilisateur = '$username'");
		my ($vendeurID)=$db->sqlSelect("id_personne", "personne,met_en_vente", "id_personne = ref_vendeur AND ref_article = $article");
		if ($userID eq $vendeurID) {		
		    print "Content-Type: text/html\n\n";
		    print "Vous ne pouvez pas acheter un article vous appartenant";					
		}else {
		    my ($existingQuantity,$price)=$db->sqlSelect("quantite, prix", "article", "id_article = '$article'");
		    my ($lastCommandInsert);
		    
		    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
		    my  $date = sprintf "%4d-%02d-%02d",$year+1900,$mon+1,$mday;
		    my  $time = sprintf("%4d:%02d",$hour,$min);
    
		    if ($existingQuantity - $quantite >= 0) {
			my $newQuantity = $existingQuantity - $quantite;
			$db->sqlUpdate("article", "id_article = '$article'",(quantite => $newQuantity));
			my ($ref_canton) = $db->sqlSelect("ref_canton","personne", "id_personne = $userID");
			my $current_price = $quantite * $price;
			$db->sqlInsert("a_paye",
					ref_article  => $article,
					ref_vendeur  => $vendeurID,
					ref_acheteur => "$userID",
					montant	=> "$current_price",
					date_fermeture_enchere => "$date $time",
					ref_mode_de_livraison =>  "$mode_livraison_ref",
					ref_statut 		 => "8",
					ref_mode_de_payement =>  "$mode_payement_ref",
					quantite     => "$quantite",
					ref_canton   => "$ref_canton"
			);
			print "Location: https://avant-garde.no-ip.biz/cgi-bin/recordz.cgi?lang=$lang&page=myencheredeal&session=$session_id&&option=mybuytobuy\n\n";
			
		    } else {
			print "Content-Type: text/html\n\n";
			print "<link href=\"/css/main.css\" rel=\"stylesheet\" type=\"text/css\" />";
			print "$SERVER{'quantity_to_much_label'}";
			print "<br/>";
			print "<br/>";
			print "<input type=\"button\" name=\"close\" value=\"Fermer\" onClick=\"window.close(); \"</input>";
			print "&nbsp;&nbsp;";
			print "<input type=\"button\" name=\"back\" value=\"Retour\" onClick=\"window.history.back(1); \"</input>";
		    }
    		}
	}else {
		    	print "Content-Type: text/html\n\n";
			print "<link href=\"/css/main.css\" rel=\"stylesheet\" type=\"text/css\" />";
			print "$ERROR{'password_wrong'}";
			print "<br/>";
			print "<br/>";
			print "<input type=\"button\" name=\"close\" value=\"Fermer\" onClick=\"window.close(); \"</input>";
			print "&nbsp;&nbsp;";
			print "<input type=\"button\" name=\"back\" value=\"Retour\" onClick=\"window.history.back(1); \"</input>";
	    
	}
}
sub updateArticleStatutIsPayed {
    my $u = $query->param("u");
    my $article = $query->param("article");
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d",$year+1900,$mon+1,$mday;	
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my $decrypted =  &RC4(&hex2string($u),$the_key);

    if ($decrypted) {
	my ($userID) = $db->sqlSelect("id_personne", "personne", "nom_utilisateur = '$decrypted'");
	my ($vendeurID) = $db->sqlSelect("ref_vendeur", "met_en_vente", "ref_article = '$article'");
	$db->sqlUpdate("a_paye","ref_article  = $article AND ref_acheteur = $userID",			
			date_payement => "$date $time",
			ref_statut 		 => "7"
	);
	$db->sqlInsert("a_livre",			
			ref_article  => "$article",
			ref_statut   => "9",
			ref_acheteur => "$userID",
			ref_vendeur  => "$vendeurID"
			
	);
	$loadPage->loadMyEnchereDeal();
    }
    
}


sub dropItemFromBasket {
   #$CGI::Session::MySQL::TABLE_NAME = 'sessions';
     $session = new CGI::Session("driver:File", $session_id, {Directory=>"$session_dir"});
     #print $session->header();

   my  $username = $session->param("username");  
   
    if ($username) {
	my  $sessionID = $session->id(); ;
	if ( $session->param("commandid") ) {
	    my  $commandid =  $session->param("commandid"); ;
	    my  $article_id = $query->param("item") ;
	    #$article_id =~ s/\W//g;
	    sqlDelete("commande_article","ref_commande	= $commandid AND  ref_article = $article_id");
	    sqlUpdate ("article","id_article = '$article_id'",(ref_statut => '3'));
	    my  ($count) = sqlSelect("count(*)", "commande_article", "ref_commande = $commandid");
	    if ($count eq '0') {
		sqlDelete("commande","id_commande = $commandid");
		$session->param("commandid",'');
	    }
	}	    
	    displayBasket();
    }
    else {
	login ();	
    }
}

sub doBuy {
    ##$CGI::Session::MySQL::TABLE_NAME = 'sessions';
    #my  $session = new CGI::Session( "driver:File", $session_id,  {Directory=>"$session_dir"} );
    #print $session->header();
    my  $session = new CGI::Session( "driver:File", $session_id,  {Directory=>"$session_dir"} );
    my  $username  =$session->param("username"); 
    #my  $dir = "C:/indigoperl/apache/htdocs/recordz/";
    #my  $id = $session->param("commandid");
    my $string4 = weekNews ();

    if ($username) {    
	my  $level = $session->param("level");
	if ($level eq '2') {
		$LINK{'admin'} = "<a href=\"javascript:void(0)\" class=\"menulink\"  onclick=\"window.open('/cgi-bin/recordz.cgi?lang=$lang&amp;page=cms_manage_article&amp;session=$session_id;','MyWindow','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=no,width=800,height=600,left=20,top=20')\">Admin</a>";
	}
	else {
		$LINK{'admin'} = "";
	 }

	print "Content-Type: text/html\n\n";
	my  $id =  $session->param("commandid"); ;
	open (FILE, "<$dir/buy.html") or die "cannot open file $dir/buy.html";
	my  $string = calculateCommand($id);
	my  $quantity = getARTICLECount($id);
	my $menu = loadMenu();
	my $cats = getCat();


	    while (<FILE>) {	    
		s/\$LABEL'\{'([\w]+)'}/ exists $SERVER{$1} ? $SERVER{$1} : $1 /eg; 
		s/\$LANG/$lang/g;
		s/\$ERROR'\{'([\w]+)'}//g;
		s/\$ARTICLE'\{'week_news'}/$string4/g;	    
		s/\$BASKET'\{'command'}/$string/g;
		s/\$ARTICLE'\{'main_menu'}/$menu/g;	
		s/\$BASKET'\{'quantity'}/$quantity/g;
		s/\$SESSIONID/$session_id/g;
		s/\$BASKET'\{'amount'}/$string/g;
		s/\$ARTICLE'\{'search'}//g;
		s/\$OPTIONS'\{'categories'}/$cats/g;
		s/\$LINK'\{'admin'}/$LINK{'admin'}/g;
		print $_;	
	    }
	    close (FILE);	    
    }else {
	login ();
    }
}

sub enchere {
	my $article = $query->param("article");
	#$article = s/^[0-9]//g;
	my $username = $query->param("username");
	my $password = $query->param("password");
	my $enchereprice= $query->param("enchereprice");
	my $price = $query->param("price");
	
	
	my  ($user_name,$user_password,$level)= ();
	 ($user_name,$user_password,$level)=$db->sqlSelect("nom_utilisateur , mot_de_passe,level",
					     "personne", "nom_utilisateur = '$username' AND mot_de_passe='$password'");
    
	
	if ($user_name && $user_password) {
		my ($userID)=$db->sqlSelect("id_personne", "personne", "nom_utilisateur = '$username'");
		my ($vendeurID)=$db->sqlSelect("id_personne", "personne,met_en_vente", "id_personne = ref_vendeur AND ref_article = $article");
		
		if ($userID ne $vendeurID) {
			
			($ARTICLE{'counter'},$ARTICLE{'enchere_date_fin'})=$db->sqlSelect("nbr_enchere,enchere_date_fin", "article", "id_article = '$article'");
			$ARTICLE{'counter'} += 1;			
			$db->sqlUpdate("article","id_article = $article",(nbr_enchere => $ARTICLE{'counter'}));
			my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
			my  $date = sprintf "%4d-%02d-%02d",$year+1900,$mon+1,$mday;	
			my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
			my  @date_time = split(/ /, $ARTICLE{'enchere_date_fin'});			
			my  $enchere_date_end = $date_time[0];
			my  $enchere_time_end = $date_time[1];			

			if ($enchere_date_end >= $date and $enchere_time_end  >= $enchere_time_end) {
				if ($enchereprice > $price) {
					#recherche de la plus haute enchere is c est pas la première enchère
					if ($ARTICLE{'counter'} ne '1') {
						($ARTICLE{'max_enchere'})=$db->sqlSelect("MAX(prix)", "enchere", "ref_article = '$article'");
					    } else {					    
						my @price_list =$db->sqlSelect("prix", "article", "id_article = '$article'");
						print "price $price_list[0]";
						$ARTICLE{'max_enchere'} = $price_list[0]
					    }
						if ($enchereprice > $ARTICLE{'max_enchere'}) {												
								        
							
							$db->sqlInsert("enchere",
									ref_enchereur		=> $userID,
									ref_article		=> $article,
									prix			=> $enchereprice,
									date_enchere		=> "$date $time"
								);
							print "Content-Type: text/html\n\n";
							print "<html>";
							print "<link href=\"/css/main.css\" rel=\"stylesheet\" type=\"text/css\" />";
							print "$SERVER{'close_me_label'}";
							print "<br/>";
							print "<br/>";
							print "<input type=\"button\" name=\"close\" value=\"Fermer\" onClick=\"window.history.back(1); \"</input>";
							print "</html>";
						} else {
							print "Content-Type: text/html\n\n";
							print "<link href=\"/css/main.css\" rel=\"stylesheet\" type=\"text/css\" />";
							print "$SERVER{'price_to_low'}";
							print "<br/>";
							print "<br/>";
							print "<input type=\"button\" name=\"close\" value=\"Fermer\" onClick=\"window.close(); \"</input>";		
							print "&nbsp;";
							print "&nbsp;";
							print "<input type=\"button\" name=\"back\" value=\"Retour\" onClick=\"window.history.back(1); \"</input>";		

						}																	
				} else {
							print "Content-Type: text/html\n\n";
							print "<link href=\"/css/main.css\" rel=\"stylesheet\" type=\"text/css\" />";
							print "$SERVER{'price_to_low'}";
							print "<br/>";
							print "<br/>";
														print "<input type=\"button\" name=\"close\" value=\"Fermer\" onClick=\"window.close(); \"</input>";		
							print "&nbsp;";
							print "&nbsp;";
							print "<input type=\"button\" name=\"back\" value=\"Retour\" onClick=\"window.history.back(1); \"</input>";		

				}
			}else {
				#enchere terminé
				print "Content-Type: text/html\n\n";
				print "enchere pas possible car fin d enchere <br/>";
			}
		} else {
			#triche
			print "Content-Type: text/html\n\n";
			print "impossible d'enchérir un article vous appartenant<br/>";
		}
	} else {
	    	print "Content-Type: text/html\n\n";
		print "Veuillez-vous enregistrer<br/>";
	    }	
}

sub loadHistoriqueIndex {
    my $article = $query->param("article");
    my  $cat = shift || '';
    my  $type = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $depot = $query->param("depot");
    $depot =~ s/[^A-Za-z0-9 ]//;
    
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  $add;
    my  $add2;
    my  $dep;
    
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

    my  ($c)= $db->sqlSelectMany("id_enchere",
			   "enchere",
			   "ref_article = $article");	
	
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
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&page=historique&amp;article=$article&amp;min_index=$min_index&amp;max_index=$max_index&cat=$cat&depot=$depot\"  class=\"menulink2\" ><-$j-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }
        
return $string;    
}

sub success {
    
}


sub loadHistoriqueLastBuyersIndex {
    my $article = $query->param("article");
    my  $cat = shift || '';
    my  $type = shift || '';
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);
    my  $depot = $query->param("depot");
    $depot =~ s/[^A-Za-z0-9 ]//;
    
    my  $string = "";
    my  $index = '0';
    my  $total = '0';
    my  $add;
    my  $add2;
    my  $dep;
    
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

    my  ($c)= $db->sqlSelectMany("ref_article",
			   "a_paye",
			   "ref_article = $article AND ref_enchere = 'NULL'");	
	
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
	$string .= "<a href=\"/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&page=historique&amp;article=$article&amp;min_index=$min_index&amp;max_index=$max_index&cat=$cat&depot=$depot\"  class=\"menulink2\" ><-$j-></a>&#160;&nbsp;";		
	$min_index += 40;	
    }
        
return $string;    
}

sub loadHistoriqueByIndex {
    my $article = $query->param("article");
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

    my  ($c)= $db->sqlSelectMany("nom_utilisateur,prix,date_enchere",
		        "enchere, personne",
		       "ref_article = $article and ref_enchereur = id_personne LIMIT $index_start, $index_end");	
    

    my $i = 0;
    my $j = 0;
    $string .= "<table>";
    while( ($ARTICLE{'nom_utilisateur'},$ARTICLE{'prix'},$ARTICLE{'date_enchere'})=$c->fetchrow()) {
	#$string .= " <label>&nbsp;&nbsp;$ARTICLE{'genre'}</label>";
	my $de = $ARTICLE{'nom_utilisateur'};
	$string .= "<td align=\"left\" width=\"253px\" height=\"100px\" style=\"background-image:url(../images/table_article_decoration.jpg);background-position:right bottom;background-repeat: no-repeat;\">&nbsp;&nbsp;&nbsp;<a href=\"javascript:;\" onClick=\"Lvl_P2P('/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&page=profil_vendeur&username=$ARTICLE{'nom_utilisateur'}',true,0500)\">$ARTICLE{'nom_utilisateur'}</a><br/>&nbsp;&nbsp;&nbsp;$ARTICLE{'prix'}<br/>&nbsp;&nbsp;&nbsp;$ARTICLE{'date_enchere'}</td>";
	$i += 1;$j += 1;
	if ($i eq 1) {$string .= "<td align=\"left\" width=\"10px\"></td>";$i = 0;}
	if ($j eq 2) {$string .= "</tr>";$string .= "<tr>";$string .= "</tr>";$string .= "<tr>";$string .= "</tr>";$string .= "<tr>";$j = 0;}
    }
    $string .= "<table>";
    return $string;
    
}

sub loadHistoriqueLastBuyersByIndex {
    my $article = $query->param("article");
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

    my  $string = "";
    my  $add;
    my  $add2;
    my  $dep;
    
    if (!$index_start ) {
	$index_start = 0;
    }
    if (!$index_end ) {
	$index_end = 5;
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

    my  ($c)= $db->sqlSelectMany("DISTINCT id_a_paye, nom_utilisateur,prix,date_payement",
		        "a_paye, personne, article",
		       "ref_article = $article and ref_acheteur = id_personne and a_paye.ref_acheteur = id_personne and a_paye.ref_article = id_article and date_payement <> '0000-00-00 00:00:00' LIMIT $index_start, $index_end");	
    

    my $i = 0;
    my $j = 0;
    $string .= "<table>";
    while( ($ARTICLE{'id_article'},$ARTICLE{'nom_utilisateur'},$ARTICLE{'prix'},$ARTICLE{'date_enchere'})=$c->fetchrow()) {
	#$string .= " <label>&nbsp;&nbsp;$ARTICLE{'genre'}</label>";
	my $de = $ARTICLE{'nom_utilisateur'};
	$string .= "<td align=\"left\" width=\"253px\" height=\"100px\" style=\"background-image:url(../images/table_article_decoration.jpg);background-position:right bottom;background-repeat: no-repeat;\">&nbsp;&nbsp;&nbsp;<a href=\"javascript:;\" onClick=\"Lvl_P2P('/cgi-bin/recordz.cgi?lang=$lang&amp;session=$session_id&page=profil_vendeur&username=$ARTICLE{'nom_utilisateur'}',true,0500)\">$ARTICLE{'nom_utilisateur'}</a><br/>&nbsp;&nbsp;&nbsp;$ARTICLE{'prix'}<br/>&nbsp;&nbsp;&nbsp;$ARTICLE{'date_enchere'}</td>";
	$i += 1;$j += 1;
	if ($i eq 1) {$string .= "<td align=\"left\" width=\"10px\"></td>";$i = 0;}
	if ($j eq 2) {$string .= "</tr>";$string .= "<tr>";$string .= "</tr>";$string .= "<tr>";$string .= "</tr>";$string .= "<tr>";$j = 0;}
    }
    $string .= "<table>";
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


sub updateArticleReceived {
    print "Content-Type: text/html\n\n";
    print "fermer moi";
    my $u = $query->param("u");
    my $decrypted =  &RC4(&hex2string($u),$the_key);
    my $article = $query->param("article");
    my $id_a_livre = $query->param("id_a_livre");
    $db->sqlUpdate("a_livre","ref_article = $article",(ref_statut => '16'));
    #envoyer un mail a l acheteur
}

sub successDeliver  {
    print "Content-Type: text/html\n\n";
    print "fermer moi";
    my $u = $query->param("u");
    my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
    my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
    my  $time = sprintf("%4d:%02d:%02d",$hour,$min,$sec);

    my $cookie_in = $query->cookie("USERNAME");
    my $decrypted =  &RC4(&hex2string($cookie_in),$the_key);

    my $note = $query->param("note");
    my $article = $query->param("article");
    my $id_a_livre = $query->param("id_a_livre");
    my ($ref_vendeur) = $db->sqlSelect("ref_vendeur", "met_en_vente", "ref_article = $article");
    my ($ref_acheteur) = $db->sqlSelect("id_personne", "personne", "nom_utilisateur = '$decrypted'");
    $db->sqlUpdate("a_livre","ref_article = $article",(ref_statut => '16'));
    $db->sqlInsert("evaluation_achat",(ref_vendeur => $ref_vendeur,ref_acheteur => $ref_acheteur, ref_article => $article, note => $note, date => "$date $time"));
    $db->sqlInsert("evaluation_article",(ref_vendeur => $ref_vendeur,ref_acheteur => $ref_acheteur, ref_article => $article, note => $note, date => "$date $time"));
    #envoyer un mail au vendeur
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




BEGIN {
    use Exporter ();
  
    @UserAction::ISA = qw(Exporter);
    @UserAction::EXPORT      = qw();
    @UserAction::EXPORT_OK   = qw(new updatePersonalData doLongerAccount loadMyEnchereDeal payedSuccess forgetPassword confirmRegistration sendNewRegistrationMailAndSms registerNewUser registerPriceNext insertCommentaire);
}
1;

