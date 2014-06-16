#!/usr/bin/perl -w
#
# Copyright 2006 VMware, Inc.  All rights reserved.

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../";

use VMware::VIRuntime;
use AppUtil::VMUtil;
use AppUtil::HostUtil;

$SIG{__DIE__} = sub{Util::disconnect()};
$Util::script_version = "1.0";

my %opts = (
            cluster => {
            type => "=s",
            help => "Cluster name",
            required => 1},
           );

# read/validate options and connect to the server 
Opts::add_options(%opts);
Opts::parse();
Opts::validate();

# connect from the server
Util::connect();
#print "Server Connected\n";
listRules();
# disconnect from the server 
Util::disconnect();
#print "Server Disconnected\n";

sub listRules {
    # Find the Cluster
    my $clusterName = Opts::get_option('cluster');
    my $cluster_view = Vim::find_entity_view(view_type => 'ClusterComputeResource',
                                            filter => { name => $clusterName });
    my $drsgroup =  @{$cluster_view->{'configurationEx'}->{'group'}};

    if (!$cluster_view) {
       Util::trace(0, "ComputeResource '" . $clusterName . "' not found\n");
       return;
    }

    # Get the rules
    my $rules = $cluster_view->configuration->rule;

    if (!$rules) {
       Util::trace(0, "No rules found for ComputeResource '" . $clusterName . "'\n");
       return;
    }

   foreach (@$rules) {
     my $rule = $_;
     my $is_enabled = $rule->enabled;
     my $rule_name = $rule->name;
     my $rule_key = $rule->key;
     my $rule_status = $rule->status;
     #print "Rule Name: " . $rule_name . "\nRule Enabled?: " . $is_enabled . "\nKey: " . $rule_key . "\nStatus: " . $rule_status . "\n";
     print "\nRule Name: " . $rule_name . "\nDRS Group: " . $drsgroup . "\nRule Enabled?: " . $is_enabled . "\nKey: " . $rule_key . "\n";
     print "\n";
     if (ref($rule) eq 'ClusterAffinityRuleSpec') {
        print "This is an affinity rule\n";
     } elsif (ref($rule) eq 'ClusterAntiAffinityRuleSpec') {
        print "This is an anti-affinity rule\n";

	my $vms = $rule->vm;
	foreach (@vms) {
		my $vm = $_;
		my vm_name=$vm->summary;
		print "$vm_name\n";
	}

     }
   }
}
