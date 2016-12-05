use v6;

#use lib 'lib';

use Test;
use Template6;

plan 1;

my $t6 = Template6.new;
$t6.add-path: 't/templates';

my $wanted = "<html>
<head>
<title>Comment test</title>
</head>
<body>
  <p>John</p>
  <p>John</p>
  <p></p>
  <p></p>
  <p>John</p>
  <p></p>
</body>
</html>
";

is $t6.process('comment', :name<John>), $wanted, 'Comment properly parsed.';
