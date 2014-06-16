#!/usr/bin/perl

use strict;
use warnings;

use VMware::VIRuntime;

my %opts = (
        cluster => {
                type => "=s",
                variable => "cluster",
                required => 1,
        },
        ruleset => {
                type => "=s",
                variable => "ruleset",
                required => 1,
        },
);

Opts::add_options(%opts);
Opts::parse();
Opts::validate();
Util::connect();

my $cluster = Opts::get_option("cluster");
my $ruleset = Opts::get_option("ruleset");

my $cluster_view = Vim::find_entity_view(
                                                view_type => "ClusterComputeResource",
                                                filter => { name => $cluster });

my $rules = $cluster_view->configuration->rule;
foreach (@$rules) { 
        my $rule = $_;
        my $rule_name = $rule->name;
	if (($rule_name) eq ($ruleset)) {
        	my $rule_key = $rule->key;
#		print "Key : " . $rule_key . "\n";
my $ruleInfo = ClusterRuleInfo->new(key => $rule_key, enabled => 0, name => $ruleset );
print "Removing affinity rule : " . $ruleInfo->name . "\n";

my $clusterRuleSpec = ClusterRuleSpec->new(operation => ArrayUpdateOperation->new('remove'), removeKey => $rule_key, info => $ruleInfo);

my @my_rules_spec = ($clusterRuleSpec);
my $clusterConfigSpec = ClusterConfigSpecEx->new(rulesSpec => \@my_rules_spec);

$cluster_view->ReconfigureComputeResource_Task(spec => $clusterConfigSpec, modify => 1);
	}
}

Util::disconnect();

BEGIN {
        $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
