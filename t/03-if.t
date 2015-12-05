use v6;

#use lib 'lib';

use Test;
use Template6;

plan 1;

my $t6 = Template6.new;
$t6.add-path: 't/templates';

my $wanted = "<html>
<head>
<title>If Test</title>
</head>
<body>
<p>This is true</p>
<p>As is this</p>
<p>And the string matches</p>
<p>The else worked properly</p>
<p>Elseif worked</p>
<p>Unless works</p>
</body>
</html>
";

is $t6.process(
  'if', 
  :shouldbetrue(True), 
  :shouldbefalse(False),
  :astring("A string"),
  :anumber(7)
),$wanted, 'If statement.';

