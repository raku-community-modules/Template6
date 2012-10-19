use v6;

#BEGIN { @*INC.unshift: './lib'; }

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

is $t6.process('insert'), $wanted, 'INSERT statement';
is $t6.process('include', :name<World>), $wanted, 'INCLUDE statement';
is $t6.process('include2'), $wanted, 'INCLUDE statement with local template data';

$wanted = "<html>
<head>
<title>Hello World</title>
</head>
<body>
<h1>Hello Universe</h1>
<h2>That's right, it changed to Universe</h2>
</body>
</html>
";


is $t6.process('process', :name<World>), $wanted, 'PROCESS statement';

