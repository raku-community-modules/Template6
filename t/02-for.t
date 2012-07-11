use v6;

BEGIN { @*INC.unshift: './lib'; }

use Test;
use Template6;

plan 1;

my $t6 = Template6.new;
$t6.add-path: 't/templates';

my $wanted = "<html>
<head>
<title>For Test</title>
</head>
<body>
<ul>
<li>First</li>
<li>Second</li>
<li>Third</li>
</ul>
<ol>
<li>One</li>
<li>Two</li>
<li>Three</li>
</ol>
</body>
</html>
";

my @ul = 'First', 'Second', 'Third';
my @ol = 'One', 'Two', 'Three';

is $t6.process('for', :title<For Test>, :ul(@ul), :ol(@ol)), $wanted, 'Basic for statement.';

