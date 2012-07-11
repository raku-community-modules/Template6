use v6;

BEGIN { @*INC.unshift: './lib'; }

use Test;
use Template6;

plan 2;

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

