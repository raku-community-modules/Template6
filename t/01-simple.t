use v6;

BEGIN { @*INC.unshift: './lib'; }

use Test;
use Template6;

plan 4;

my $t6 = Template6.new;
$t6.add-path: 't/templates';

my $wanted = "<html>
<head>
<title>Hello World</title>
</head>
<body>
<h1>Hello World</h1>
</body>
</html>
";

is $t6.process('get', :name<World>), $wanted, 'Get statement.';
is $t6.process('set'), $wanted, 'Set statement.';
is $t6.process('default', :name<World>), $wanted, 'Default statement.';

$wanted = "<html>
<head>
<title>Hello Universe</title>
</head>
<body>
<h1>Hello Universe</h1>
</body>
</html>
";

is $t6.process('get', :name<Universe>), $wanted, 'Second get on already compiled template.';

