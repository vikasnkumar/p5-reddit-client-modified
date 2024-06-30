package Reddit::Client::Comment;

use strict;
use warnings;
use Carp;

require Reddit::Client::VotableThing;
# comments don't have over_18 and is_self, do they?
use base   qw/Reddit::Client::VotableThing/;
use fields qw/ 
approved_by
author
author_flair_css_class
author_flair_text
banned_by
body
body_html
can_mod_post
clicked
created
created_utc
domain
hidden
is_self
link_author
link_id
link_permalink
link_title
link_url
locked
media_embed
mod_reports
more
num_comments
num_reports
over_18
parent_id
permalink
quarantine
removed
replies
saved
selftext
selftext_html
spam
stickied
subreddit
subreddit_id
thumbnail
title
user_reports
/;

use constant type => "t1";
# This is called by the magic in Thing.pm on creation
sub set_replies { 
    my ($self, $value) = @_;
    if (ref $value && exists $value->{data}{children}) {
		my $comments = $value->{data}{children};
		my $return = [];

		for my $cmt (@$comments) {
			# 'kind' is on same level as 'data'
			if ($cmt->{kind} eq 't1') {
				push @$return, Reddit::Client::Comment->new($self->{session}, $cmt->{data});
			} elsif ($cmt->{kind} eq 'more') {
				my $more = Reddit::Client::MoreComments->new($self->{session}, $cmt->{data});
				$more->{link_id} = $self->{link_id};
				$self->{more} = $more->{children};
				push @$return, $more;
			}
		}
		
		$self->{replies} = $return;
    } else {
        $self->{replies} = [];
    }
}
# need fix this
sub get_collapsed_comments {
	my ($self, %param) = @_;
	return undef if !$self->{more} or ref $self->{more} ne 'ARRAY';
	
	my %data = (
		link_id		=> $self->{link_id},
		children	=> $self->{more},
	);
	$data{sort}	= $param{sort} if $param{sort};
	$data{id}	= $param{id} if $param{id};

	return $self->{session}->get_collapsed_comments( %data );
}

sub reply {
    my ($self, $text) = @_;
	my $cmtid = $self->{session}->submit_comment(parent_id=>$self->{name}, text=>$text);
	return $cmtid;
}
sub remove {
	my $self = shift;
	return $self->{session}->remove($self->{name});
}
sub spam {
	my $self = shift;
	return $self->{session}->spam($self->{name});
}
sub approve {
	my $self = shift;
	return $self->{session}->approve($self->{name});
}
sub ignore_reports {
	my $self = shift;
	return $self->{session}->ignore_reports($self->{name});
}
sub edit {
    	my ($self, $text) = @_;
	my $cmtid = $self->{session}->edit($self->{name}, $text);
	$self->{body} = $text if $cmtid;
	return $cmtid;
}
sub delete {
    	my $self = shift;
	my $cmtid = $self->{session}->delete($self->{name});
	return $cmtid;
}
sub get_permalink { 	# deprecated. Duplicated instead of calling get_web_url
	my $self = shift;	# because this may (and probably will) change someday
	return $self->{session}->get_origin().$self->{permalink}
}
sub get_web_url {
	my $self = shift;
	return $self->{session}->get_origin().$self->{permalink}
}
sub get_children {
	my $self = shift;
	my $cmts = $self->{session}->get_comments(permalink=>$self->{permalink});
	$self->{replies} = $$cmts[0]->{replies}; # populate this comment's replies
	return $$cmts[0]->{replies}; 
}
sub get_comments {
	my $self = shift;
	my $cmts = $self->{session}->get_comments(permalink=>$self->{permalink});
	$self->{replies} = $$cmts[0]->{replies}; # populate this comment's replies
	return $cmts;
}

sub has_collapsed_children {
	my $self = shift;
	return $self->{more} ? 1 : 0;
}

sub replies {
    return shift->{replies};
}
1;

__END__

=pod

=head1 NAME

Reddit::Client::Comment

=head1 DESCRIPTION

Wraps a posted comment.

=head1 SUBROUTINES/METHODS

=over

=item replies()

Returns a list ref of replies underneath this comment.

=item reply

=item remove

=item spam

=item approve

=item ignore_reports

=back

=head1 INTERNAL ROUTINES

=over

=item set_replies

Wraps the list of children in Comment class instances and ensures that comments
with no replies return an empty array for C<replies>.

=back

=head1 AUTHOR

<mailto:earthtone.rc@gmail.com>

=head1 LICENSE

BSD license

=cut
