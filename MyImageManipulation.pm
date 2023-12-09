#!/usr/bin/perl -w
package MyImageManipulation;
use strict;
use SharedVariable qw ($action $session_dir $dir $dirLang $dirError $imgdir $session_id $can_do_gzip $current_ip $lang $LANG %ARTICLE %SESSION %SERVER %USER $CGISESSID %LABEL %ERROR %VALUE $COMMANDID %COMMAND %DATE %PAYPALL $INDEX %LINK  $query $session $host $t0  $client);  
use Image::Thumbnail;
use MyDB;

our $mydb = MyDB->new;

sub new {
        my $class = shift;
        my ($opts)= @_;
	my $self = {};
	return bless $self, $class;
}

sub showImage {
    my $call = shift || '';
    my  $image = $query->param('article');
    my  $URL = "../upload/$image.jpg";
    my $content;
	my $ARTICLE_URL = {};
	if (defined $image) {
		open (FILE, "<$dir/show_image.html") or die "cannot open file $dir/show_image.html";
		while (<FILE>) {
			s/\$ARTICLE_URL/$URL/g;
			$content .= $_;
		}
	}
	print "Content-Type: text/html\n\n";
	print $content;
    close (FILE);    
    return 1;
}


sub showImage2 {
    my $call = shift || '';
    my  $image = $query->param('image');
    my  $URL = "../upload/$image";
    my $content;
	my $ARTICLE_URL = "";
	if (defined $image) {
		open (FILE, "<$dir/show_image.html") or die "cannot open file $dir/show_image.html";
		while (<FILE>) {
			s/\$ARTICLE_URL/$URL/g;
			$content .= $_;
		}
	}
	$content = Compress::Zlib::memGzip($content)  if $can_do_gzip;print "Content-Length: ", length($content) , "\n";print "Content-Encoding: gzip\n" ;print "Content-Type: text/html\n\n";print $content;
    close (FILE);    
}

sub uploadImage {
    my $call = shift || '';
    my  $name = shift || '';
    my  $file = $query->param('image');
    #$file =~ s/[^A-Za-z0-9 ]//;
    if ($file) {
	my  $tmpfile=$file;
	my  $buffer;    
	#unlink("C:/Apache2/htdocs/recordzupload/$name.jpg") or die "could not remove file";
	open (OUTFILE,">>C:/Users/41786/OneDrive/Documents/recordz1/upload/$name.jpg");
	binmode OUTFILE; 
	    while (my  $bytesread=read($file,$buffer,1024)) {
	       print OUTFILE $buffer;
	       print $_;
	    }
	close (OUTFILE);
	#system("chmod 777 C:/Apache2/htdocs/recordzupload/$name.jpg");
    
    
	createTumb($name,".jpg");
    }
}


sub uploadImages {
    my $call = shift || '';
    my  $name = shift || '';
    my  $file2 = $query->param('image2');
    my  $file3 = $query->param('image3');
    my  $file4 = $query->param('image4');    
    #$file =~ s/[^A-Za-z0-9 ]//;
  
    if ($file2) {
	my  $tmpfile=$file2;
	my  $buffer;    
	#unlink("C:/Apache2/htdocs/recordzupload/$name.jpg") or die "could not remove file";
	open (OUTFILE,">>C:/Users/41786/OneDrive/Documents/recordz1/upload/$name."."2.jpg");
	binmode OUTFILE; 
	    while (my  $bytesread=read($file2,$buffer,1024)) {
	       print OUTFILE $buffer;
	       print $_;
	    }
	close (OUTFILE);
	#system("chmod 777 C:/Apache2/htdocs/recordzupload/$name.jpg");
    
    
	createTumb($name.".2",".jpg");
    }
    if ($file3) {
	my  $tmpfile=$file3;
	my  $buffer;    
	#unlink("C:/Apache2/htdocs/recordzupload/$name.jpg") or die "could not remove file";
	open (OUTFILE,">>C:/Users/41786/OneDrive/Documents/recordz1/upload/$name."."3.jpg");
	binmode OUTFILE; 
	    while (my  $bytesread=read($file3,$buffer,1024)) {
	       print OUTFILE $buffer;
	       print $_;
	    }
	close (OUTFILE);
	#system("chmod 777 C:/Apache2/htdocs/recordzupload/$name.jpg");
    
    
	createTumb($name.".3",".jpg");
    }
    if ($file4) {
	my  $tmpfile=$file4;
	my  $buffer;    
	#unlink("C:/Apache2/htdocs/recordzupload/$name.jpg") or die "could not remove file";
	open (OUTFILE,">>C:/Users/41786/OneDrive/Documents/recordz1/upload/$name."."4.jpg");
	binmode OUTFILE; 
	    while (my  $bytesread=read($file4,$buffer,1024)) {
	       print OUTFILE $buffer;
	       print $_;
	    }
	close (OUTFILE);
	#system("chmod 777 C:/Apache2/htdocs/recordzupload/$name.jpg");
    
    
	createTumb($name.".4",".jpg");
    }

}


sub createTumb {
	my $filename = shift || '';
	my $extension = shift || '';
	

	my $src_dir = "C:/Users/41786/OneDrive/Documents/recordz1/upload/";
	my $dest_dir = "C:/Users/41786/OneDrive/Documents/recordz1/upload/$filename";
	mkdir $dest_dir;
    	my $t = new Image::Thumbnail(
	module => 'GD',
	size => 100,
	create => 1,
	inputpath => "$src_dir/$filename$extension",
	outputpath => "$dest_dir/thumb.$filename.png",
	);
}

sub generateGraphicDeal {
	my $call = shift || '';
	my $username = shift || '';my $nbr;my $nbr2;my @array = ();my @array2= ();
	my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
        my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;	
	my @xLabels  = qw(Jan  Fév Mar Avr Mai Jui Jui Aou Sep Oct Nov Dec);
	($ARTICLE{'eval_count'})= sqlSelect("count(*)", "personne,evaluation_vente","nom_utilisateur = '$username' AND evaluation_vente.ref_vendeur = id_personne  AND note BETWEEN 5 AND 10");	
	($ARTICLE{'eval_count_neg'})= sqlSelect("count(*)", "personne,evaluation_vente","nom_utilisateur = '$username' AND evaluation_vente.ref_vendeur = id_personne  AND note BETWEEN 0 AND 4");	
	my $j;
	for (my $i = 1; $i <= 12;$i++) {
	    if ($i eq '1' or $i eq '2' or $i eq '3' or $i eq '4' or $i eq '5' or $i eq '6' or $i eq '7' or $i eq '8' or $i eq '9') {$j = "0" .$i;}else {$j = $i;}	
		($ARTICLE{'eval_sum'})= sqlSelect("sum(note)", "personne,evaluation_vente","nom_utilisateur = '$username' AND evaluation_vente.ref_vendeur = id_personne AND date like '%-$j-%' AND note BETWEEN 5 AND 10");
		$nbr = $ARTICLE{'eval_sum'} / $ARTICLE{'eval_count'} if $ARTICLE{'eval_count'} ne 0;
		$array[ $i -1 ] = $nbr;
		($ARTICLE{'eval_sum_neg'})= sqlSelect("sum(note)", "personne,evaluation_vente","nom_utilisateur = '$username' AND evaluation_vente.ref_vendeur = id_personne AND date like '%-$j-%' AND note BETWEEN 0 AND 4");
		$nbr2 = $ARTICLE{'eval_sum_neg'} / $ARTICLE{'eval_count_neg'} if $ARTICLE{'eval_count_neg'} ne 0;
		$array2[ $i -1 ] = $nbr2;
	}
	my @data = ( \@xLabels,\@array2,\@array );	
	my $graph = GD::Graph::bars->new(500, 300);
	$graph->set( title   => "$SERVER{'eval_deal'}", y_label => "$SERVER{'deal_nbr'}");
	$graph->set_legend( "Négatif ($ARTICLE{'eval_count_neg'})","Positif ($ARTICLE{'eval_count'})");
	my $gd = $graph->plot(\@data);
	binmode STDOUT;	
	open(GRAPH,">$dir/images/$username._evalbuy.jpg") || die "Cannot open $dir/images/$username._evalbuy.jpg : $!\n";
	binmode GRAPH;
	print GRAPH $graph->gd->jpeg(100);
	close(GRAPH);
	return "<img alt=\"\" src=\"../images/$username._evalbuy.jpg\">";	
}

    
sub uploadPochette {
    my $call = shift || '';
    my  $uploadfile = $query->param('uploadfile'); 
    my  $uploadfilename = $uploadfile;
    if ($uploadfile) {    

    my  $buffer = '';

    if (open(NEW, ">$dir/$uploadfile")) {
	while (read($uploadfile, $buffer, 1024)){
		print NEW $buffer;
	}
	close NEW;
    }
    }
}
    
sub generateGraphicBuy {
        my $call = shift || '';
	my $username = shift || '';
	my $nbr;
	my $nbr2;
	my @array = ();
	my @array2= ();
	my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
        my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
	
	my @xLabels  = qw(Jan  Fév Mar Avr Mai Jui Jui Aou Sep Oct Nov Dec);
	($ARTICLE{'eval_count'})= $mydb->sqlSelect("count(*)", "personne,evaluation_achat","nom_utilisateur = '$username' AND evaluation_achat.ref_acheteur = id_personne  AND note BETWEEN 5 AND 10");	
	($ARTICLE{'eval_count_neg'})= $mydb->sqlSelect("count(*)", "personne,evaluation_achat","nom_utilisateur = '$username' AND evaluation_achat.ref_acheteur = id_personne  AND note BETWEEN 0 AND 4");	
	#SUM
	my $j;
	for (my $i = 1; $i < 13;$i++) {
	    if ($i eq '1' or $i eq '2' or $i eq '3' or $i eq '4' or $i eq '5' or $i eq '6' or $i eq '7' or $i eq '8' or $i eq '9') {
		$j = "0" .$i;
	    }else {
		$j = $i;
	    }
		($ARTICLE{'eval_sum'})= $mydb->sqlSelect("sum(note)", "personne,evaluation_achat","nom_utilisateur = '$username' AND evaluation_achat.ref_acheteur = id_personne AND date like '%-$j-%' AND note BETWEEN 5 AND 10");
		$nbr = $ARTICLE{'eval_sum'} / $ARTICLE{'eval_count'} if $ARTICLE{'eval_count'} ne 0;
		$array[ $i -1 ] = $nbr;
		($ARTICLE{'eval_sum_neg'})= $mydb->sqlSelect("sum(note)", "personne,evaluation_achat","nom_utilisateur = '$username' AND evaluation_achat.ref_acheteur = id_personne AND date like '%-$j-%' AND note BETWEEN 0 AND 4");
		$nbr2 = $ARTICLE{'eval_sum_neg'} / $ARTICLE{'eval_count_neg'} if $ARTICLE{'eval_count_neg'} ne 0;
		$array2[ $i -1 ] = $nbr2;
	}
	my @data = ( \@xLabels,\@array2,\@array );
	
	my $graph = GD::Graph::bars->new(500, 300);
	$graph->set( title   => "$SERVER{'eval_deal'}",
		     y_label => "$SERVER{'deal_nbr'}");
	$graph->set_legend( "Négatif ($ARTICLE{'eval_count_neg'})",
			    "Positif ($ARTICLE{'eval_count'})");
	my $gd = $graph->plot(\@data);
	binmode STDOUT;
	
	open(GRAPH,">C:/Users/41786/OneDrive/Documents/recordz1/upload/$username._evaldeal.jpg") || die "Cannot open /home/alexandre/apache/site/recordz1/upload/$username._evaldeal.jpg : $!\n";
	binmode GRAPH;
	print GRAPH $graph->gd->jpeg(100);
	close(GRAPH);
	return "<img alt=\"\" src=\"../upload/$username._evaldeal.jpg\">";	
}


sub generateGraphicStatArticleBrand {
	return "test";
}
sub generateGraphicStatArticleBrandTEST {
        my $call = shift || '';
	my $brand = shift || '';
	if ($brand =~ m/'/)  {
	    $brand=~ s/\'/\'\'/g;
	}
	
	my $username = shift || '';
	my $nbr;
	my $nbr2;
	my @array = ();
	my @array2= ();
	my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
        my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
	
	my @xLabels  = qw(Jan  Fév Mar Avr Mai Jui Jui Aou Sep Oct Nov Dec);	
	#SUM
	my $j;
	for (my $i = 1; $i < 13;$i++) {
	    if ($i eq '1' or $i eq '2' or $i eq '3' or $i eq '4' or $i eq '5' or $i eq '6' or $i eq '7' or $i eq '8' or $i eq '9') {
		$j = "0" .$i;
	    }else {
		$j = $i;
	    }
	    ($ARTICLE{'eval_count'})= $mydb->sqlSelect("count(*)", "personne,article,a_paye","nom_utilisateur = '$username' AND a_paye.ref_vendeur = id_personne  and a_paye.ref_article = article.id_article and article.marque = '$brand' and a_paye.date_payement LIKE '%-$j-%'");	
             $array[ $i -1 ] = $ARTICLE{'eval_count'};
	}
	my @data = ( \@xLabels,\@array );
	
	my $graph = GD::Graph::bars->new(500, 300);
	$graph->set( title   => "$brand",
		     y_label => "Quantity");
	$graph->set_legend( "$brand)",
			    "$brand");
	my $gd = $graph->plot(\@data);
	binmode STDOUT;
	
	open(GRAPH,">C:/Users/41786/OneDrive/Documents/recordz1/upload/$username._evalbrand.jpg") || die "Cannot open /home/alexandre/apache/site/recordz1/upload/$username._evalbrand.jpg : $!\n";
	binmode GRAPH;
	print GRAPH $graph->gd->jpeg(100);
	close(GRAPH);
	return "<img alt=\"\" src=\"../upload/$username._evalbrand.jpg\">";	
}

sub generateGraphicStatArticleCanton {
        my $call = shift || '';
	my $brand = shift || '';
	my $username = shift || '';
	my $nbr;
	my $nbr2;
	my @array = ();
	my @array2= ();
	my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
        my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
	
	my @xLabels  = qw(Jan  Fév Mar Avr Mai Jui Jui Aou Sep Oct Nov Dec);	
	#SUM
	my $j;
	for (my $i = 1; $i < 13;$i++) {
	    if ($i eq '1' or $i eq '2' or $i eq '3' or $i eq '4' or $i eq '5' or $i eq '6' or $i eq '7' or $i eq '8' or $i eq '9') {
		$j = "0" .$i;
	    }else {
		$j = $i;
	    }
	    my %OPTIONS = ();
	    my $total;
	    my ($ref_canton) = $mydb->sqlSelect("id_canton","canton_fr", "nom = '$brand'");
	    my ($c) = $mydb->sqlSelectMany("distinct (id_a_paye)", "personne,article,a_paye,met_en_vente","nom_utilisateur = '$username' AND met_en_vente.ref_vendeur = id_personne  and a_paye.ref_article = article.id_article and a_paye.ref_canton = $ref_canton and a_paye.date_payement LIKE '%-$j-%'");
	    while(($OPTIONS{'category'})=$c->fetchrow()) {	
		$total = $total + 1;
	    }
	    ($ARTICLE{'eval_count'}) = $total;
	    
             $array[ $i -1 ] = $ARTICLE{'eval_count'};
	}
	my @data = ( \@xLabels,\@array );
	
	my $graph = GD::Graph::bars->new(500, 300);
	$graph->set( title   => "$brand",
		     y_label => "Quantity");
	$graph->set_legend( "$brand)",
			    "$brand");
	my $gd = $graph->plot(\@data);
	binmode STDOUT;
	
	open(GRAPH,">C:/Users/41786/OneDrive/Documents/recordz1/upload/$username._evalcanton.jpg") || die "Cannot open /home/alexandre/apache/site/recordz1/upload/$username._evalcanton.jpg : $!\n";
	binmode GRAPH;
	print GRAPH $graph->gd->jpeg(100);
	close(GRAPH);
	return "<img alt=\"\" src=\"../upload/$username._evalcanton.jpg\">";	
}
BEGIN {
    use Exporter ();
  
    @MyImageManipulation::ISA = qw(Exporter);
    @MyImageManipulation::EXPORT      = qw();
    @MyImageManipulation::EXPORT_OK   = qw(new uploadPochette generateGraphicBuy generateGraphicDeal createTumb uploadImages showImage showImage2);
}
1;