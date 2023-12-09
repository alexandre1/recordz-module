#!/usr/bin/perl -w
package ImageManipulation;
use strict;
use DBI;
use SharedVariable qw ($action $session_dir $dir $dirLang $dirError $imgdir $session_id $can_do_gzip $current_ip $lang $LANG %ARTICLE %SESSION %SERVER %USER $CGISESSID %LABEL %ERROR %VALUE $COMMANDID %COMMAND %DATE %PAYPALL $INDEX %LINK  $query $session $host $t0  $client);  
use base qw (SharedVariable);
my $dir = "C:/Users/41786/OneDrive/Documents/recordz1/";
my $dirLang = "C:/Users/41786/OneDrive/Documents/recordz1/lang";
my $dirError = "C:/Users/41786/OneDrive/Documents/recordz1/lang";
my $imgdir=  "C:/Users/41786/OneDrive/Documents/recordz1/upload";
our $dbh = DBI->connect( "DBI:mysql:recordz:localhost", "root", "",{ RaiseError => 1, AutoCommit => 1 } );

sub new {
        my $class = shift;
        my ($opts)= @_;
	my $self = {};
        
	return bless $self, $class;
}



sub showImage {
my  $image = $query->param('image');
my  $URL = "../upload/$image.jpg";
my $content;
open (FILE, "<$dir/show_image.html") or die "cannot open file $dir/show_image.html";
while (<FILE>) {s/\$ARTICLE{'url_image'}/$URL/g;$content .= $_;}
    print "Content-Type: text/html\n\n";
    print $content;
close (FILE);    
return 1;
}


sub showImage2 {
my  $image = $query->param('image');my  $URL = "../upload/$image";my $content;
open (FILE, "<$dir/show_image.html") or die "cannot open file $dir/show_image.html";
while (<FILE>) {s/\$ARTICLE{'url_image'}/$URL/g;$content .= $_;}
$content = Compress::Zlib::memGzip($content)  if $can_do_gzip;print "Content-Length: ", length($content) , "\n";print "Content-Encoding: gzip\n" ;print "Content-Type: text/html\n\n";print $content;
close (FILE);    
}

sub uploadImage {
    my  $name = shift || '';
    my  $file = $query->param('image');
    #$file =~ s/[^A-Za-z0-9 ]//;
    if ($file) {
	my  $tmpfile=$file;
	my  $buffer;    
	#unlink("C:/Apache2/htdocs/recordzupload/$name.jpg") or die "could not remove file";
	open (OUTFILE,">>$imgdir/$name.jpg");
	binmode OUTFILE; 
	    while (my  $bytesread=read($file,$buffer,1024)) {
	       print OUTFILE $buffer;
	       print $_;
	    }
	close (OUTFILE);
	#system("chmod 777 C:/Apache2/htdocs/recordzupload/$name.jpg");
    
    
	createTumb($name.".jpg");
    }
}


sub uploadImages {
    my  $name = shift || '';
    my  $file = $query->param('image');
    my  $file2 = $query->param('image2');
    my  $file3 = $query->param('image3');
    my  $file4 = $query->param('image4');
    #$file =~ s/[^A-Za-z0-9 ]//;
        
    my  $tmpfile=$file;
    my  $tmpfile2=$file2;
    my  $tmpfile3=$file3;
    my  $tmpfile4=$file4;
    my  $buffer;
    
    #unlink("C:/Apache2/htdocs/recordzupload/$name.jpg") or die "could not remove file";
    open (OUTFILE,">>$imgdir/$name.jpg");
    if ($file2) {
    open (OUTFILE2,">>$imgdir/$name.2.jpg");
    }
    if ($file3) {
	open (OUTFILE3,">>$imgdir/$name.3.jpg");
    }
    if ($file4) {
	open (OUTFILE4,">>$imgdir/$name.4.jpg");
    }
    binmode OUTFILE;
    if ($file2) {
    binmode OUTFILE2;
    }
    if ($file3) {
    binmode OUTFILE3;
    }
    if ($file4) {
    binmode OUTFILE4;
    }
    
        while (my  $bytesread=read($file,$buffer,1024)) {
           print OUTFILE $buffer;
	   print $_;
        }
    close (OUTFILE);
    $buffer = "";
    if ($file2) {while (my  $bytesread=read($file2,$buffer,1024)) {print OUTFILE2 $buffer;print $_;}	
    close (OUTFILE2);
    }
    $buffer = "";
     if ($file3) {while (my  $bytesread=read($file3,$buffer,1024)) {print OUTFILE3 $buffer;print $_;}close (OUTFILE3);}
    $buffer = "";
     if ($file4) {while (my  $bytesread=read($file4,$buffer,1024)) {print OUTFILE4 $buffer;print $_;} close (OUTFILE4);}
    createTumb($name.".jpg");
    if ($file2) {createTumb($name.".2.jpg");}
    if ($file3) {createTumb($name.".3.jpg");}
    if ($file4) {createTumb($name.".4.jpg");}
}

sub createTumb {
    
    my  $filename = shift || '';
    open (IN, "<C:/Apache2/htdocs/recordz/upload/$filename")  or die "Could not open C:/Apache2/htdocs/recordz/upload/$filename";
    my  $srcImage = GD::Image->newFromJpeg(*IN);
    close IN;
    my  ($thumb,$x,$y) = Image::GD::Thumbnail::create($srcImage,50);
    open (OUT,">>C:/Apache2/htdocs/recordz/upload/thumb.$filename") or die "Could not save ";
    binmode OUT;
    print OUT $thumb->jpeg;
    close OUT;
}

sub generateGraphicDeal {
	my $username = shift || '';my $nbr;my $nbr2;my @array = ();my @array2= ();
	my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
        my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;	
	my @xLabels  = qw(Jan  F�v Mar Avr Mai Jui Jui Aou Sep Oct Nov Dec);
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
	$graph->set_legend( "N�gatif ($ARTICLE{'eval_count_neg'})","Positif ($ARTICLE{'eval_count'})");
	my $gd = $graph->plot(\@data);
	binmode STDOUT;	
	open(GRAPH,">c:/Users/41786/OneDrive/Documents/recordz1/upload/$username._evalbuy.jpg") || die "Cannot open $dir/images/$username._evalbuy.jpg : $!\n";
	binmode GRAPH;
	print GRAPH $graph->gd->jpeg(100);
	close(GRAPH);
	return "<img alt=\"\" src=\"../images/$username._evalbuy.jpg\">";	
}

sub generateGraphicBuy {
	my $username = shift || '';
	my $nbr;
	my $nbr2;
	my @array = ();
	my @array2= ();
	my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
        my  $date = sprintf "%4d-%02d-%02d \n",$year+1900,$mon+1,$mday;
	
	my @xLabels  = qw(Jan  F�v Mar Avr Mai Jui Jui Aou Sep Oct Nov Dec);
	($ARTICLE{'eval_count'})= sqlSelect("count(*)", "personne,evaluation_achat","nom_utilisateur = '$username' AND evaluation_achat.ref_acheteur = id_personne  AND note BETWEEN 5 AND 10");	
	($ARTICLE{'eval_count_neg'})= sqlSelect("count(*)", "personne,evaluation_achat","nom_utilisateur = '$username' AND evaluation_achat.ref_acheteur = id_personne  AND note BETWEEN 0 AND 4");	
	#SUM
	my $j;
	for (my $i = 1; $i < 13;$i++) {
	    if ($i eq '1' or $i eq '2' or $i eq '3' or $i eq '4' or $i eq '5' or $i eq '6' or $i eq '7' or $i eq '8' or $i eq '9') {
		$j = "0" .$i;
	    }else {
		$j = $i;
	    }
		($ARTICLE{'eval_sum'})= sqlSelect("sum(note)", "personne,evaluation_achat","nom_utilisateur = '$username' AND evaluation_achat.ref_acheteur = id_personne AND date like '%-$j-%' AND note BETWEEN 5 AND 10");
		$nbr = $ARTICLE{'eval_sum'} / $ARTICLE{'eval_count'} if $ARTICLE{'eval_count'} ne 0;
		$array[ $i -1 ] = $nbr;
		($ARTICLE{'eval_sum_neg'})= sqlSelect("sum(note)", "personne,evaluation_achat","nom_utilisateur = '$username' AND evaluation_achat.ref_acheteur = id_personne AND date like '%-$j-%' AND note BETWEEN 0 AND 4");
		$nbr2 = $ARTICLE{'eval_sum_neg'} / $ARTICLE{'eval_count_neg'} if $ARTICLE{'eval_count_neg'} ne 0;
		$array2[ $i -1 ] = $nbr2;
	}
	my @data = ( \@xLabels,\@array2,\@array );
	
	my $graph = GD::Graph::bars->new(500, 300);
	$graph->set( title   => "$SERVER{'eval_deal'}",
		     y_label => "$SERVER{'deal_nbr'}");
	$graph->set_legend( "N�gatif ($ARTICLE{'eval_count_neg'})",
			    "Positif ($ARTICLE{'eval_count'})");
	my $gd = $graph->plot(\@data);
	binmode STDOUT;
	
	open(GRAPH,">c:/Users/41786/OneDrive/Documents/recordz1/upload/$username._evaldeal.jpg") || die "Cannot open $dir/images/$username._evaldeal.jpg : $!\n";
	binmode GRAPH;
	print GRAPH $graph->gd->jpeg(100);
	close(GRAPH);
	return "<img alt=\"\" src=\"../images/$username._evaldeal.jpg\">";	
}


sub uploadPochette {
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

	our $dbh = DBI->connect( "DBI:mysql:recordz:localhost", "root", "",{ RaiseError => 1, AutoCommit => 1 } );

sub new {
        my $class = shift;
        my ($opts)= @_;
	my $self = {};
	return bless $self, $class;
}

sub sqlConnect {
	my  $dbname = shift || '';
	my  $dbusername = shift || '';
	my  $dbpassword = shift || '';

	$dbh = DBI->connect($dbname, $dbusername, $dbpassword);
	if (!$dbh) {
	}
	kill 9, $$ unless $dbh;
}

sub sqlSelect {
	my  $select = shift || '';
	my  $from = shift || '';
	my  $where = shift || '';
	my  $other = shift || '';


	my  $sql="SELECT $select ";
	$sql.="FROM $from " if $from;
	$sql.="WHERE $where " if $where;
	$sql.="$other" if $other;
	#$sql = $dbh->quote ($sql);
	#print "Content-Type: text/html\n\n";
	#print "sql : $sql\n";
	my  ($c)=$dbh->prepare($sql) or die "Sql has gone to hell\n";

	if(not ($c->execute())) {
		my  $err=$dbh->errstr;
		return undef;
	}
	my  (@r)=$c->fetchrow();
	$c->finish();
	return @r;
}

sub sqlInsert {
	my ($table,%data)=@_;

	my ($names,$values);
	$dbh||=sqlConnect();
	foreach (keys %data) {
		if (/^-/) {$values.="\n  ".$data{$_}.","; s/^-//;}
		else { $values.="\n  ".$dbh->quote($data{$_}).","; }
		$names.="$_,";
	}

	chop($names);
	chop($values);

	my  $sql="INSERT INTO $table ($names) VALUES($values)\n";
	#$sql = $dbh->quote ($sql);
	#print "Content-Type: text/html\n\n";
	#print "$sql <br />";

	if(!$dbh->do($sql)) {
		my  $err=$dbh->errstr;
	}
}

sub sqlUpdate {
	my ($table, $where, %data)=@_;

	my  $sql="UPDATE $table SET";

	foreach (keys %data) {
		if (/^-/) {
			s/^-//;
			$sql.="  $_ = $data{-$_} " . ",";
		} else {
			$sql.="  $_ = ".$dbh->quote($data{$_}).",";
		}
	}
	chop($sql);	
	$sql.=" WHERE $where ";
#	$sql = $dbh->quote ($sql);
#	print "Content-Type: text/html\n\n";
#	print "$sql";
	if(!$dbh->do($sql)) {
	    my  $err=$dbh->errstr;
	}
}

sub sqlSelectMany {
	my  $select = shift || '';
	my  $from = shift || '';
	my  $where = shift || '';
	my  $other = shift || '';

	my  $sql="SELECT $select ";
	$sql.="FROM $from " if $from;
	$sql.="WHERE $where " if $where;
	$sql.="$other" if $other;
	#print "Content-Type: text/html\n\n";
	#print "$sql";
	#$sql = $dbh->quote ($sql);
	my  $c=$dbh->prepare($sql);

	if($c->execute()) {
		return $c;
	} else {
		$c->finish();
		my  $err=$dbh->errstr;
		return undef;
		kill 9,$$
	}
}

sub sqlDelete {
	my  $fromtable = shift || '';
	my  $condition = shift || '';

	my  $sql = '';
	if ($condition) {
		$sql = "DELETE from $fromtable WHERE $condition";
	} else {
		$sql = "DELETE from $fromtable";
	}
	#print "Content-Type: text/html\n\n";
	#print "$sql";
	#$sql = $dbh->quote ($sql);	
	if (!$dbh->do($sql)) {
		my  $err=$dbh->errstr;
	}
}
}
