use v6;

BEGIN { @*INC.unshift: './lib'; }

use Test;
use Template6;

plan 2;

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

$wanted = "<html>
<head>
<title>For Hash Test</title>
</head>
<body>
<table>
<tr>
<th>Email</th>
<th>Age</th>
</tr>
<tr>
<td>bob\@smith.com</td>
<td>27</td>
</tr>
<tr>
<td>lisa\@abbot.org</td>
<td>18</td>
</tr>
<tr>
<td>melissa\@senstry.com</td>
<td>31</td>
</tr>
</table>
</body>
</html>
";

my %users = 
{ 
  'bob@smith.com'        => 27,
  'lisa@abbot.org'       => 18,
  'melissa@senstry.com' => 31,
};

is $t6.process('for-hash', :title<For Hash Test>, :users(%users)), $wanted, 'For statement with hash.';

