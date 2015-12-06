use v6;

#use lib 'lib';

use Test;
use Template6;

plan 2;

my $t6 = Template6.new;
$t6.add-path: 't/templates';

my $wanted = "<html>
<head>
<title>Nesting Test</title>
</head>
<body>
<table>
<tr>
<th>User</th>
<th>Age</th>
<th>Job</th>
</tr>
<tr>
<td>Bob</td>
<td>27</td>
<td>CEO</td>
</tr>
<tr>
<td>Lisa</td>
<td>18</td>
<td>Marketing</td>
</tr>
<tr>
<td>Melissa</td>
<td>31</td>
<td>VP Sales</td>
</tr>
</table>
</body>
</html>
";

my @users =
{
  :name<Bob>,
  :age(27),
  :job<CEO>,
},
{
  :name<Lisa>,
  :age(18),
  :job<Marketing>,
},
{
  :name<Melissa>,
  :age(31),
  :job<VP Sales>,
};

is $t6.process('simple-nest', :users(@users)), $wanted, 'Nested data with array of hashes';

class CompanyUser {
  has $.name;
  has $.job;
  has $.birthday;

  method age {
    ## A real application would use today, but our test is hard coded.
    #my $now = Date.today;  
    my $now = Date.new('2012-07-17');
    return (($now - $.birthday) / 365).Int;
  }
}

@users =
CompanyUser.new(:name<Bob>,     :job<CEO>,       :birthday(Date.new('1985-07-13'))),
CompanyUser.new(:name<Lisa>,    :job<Marketing>, :birthday(Date.new('1994-05-11'))),
CompanyUser.new(:name<Melissa>, :job<VP Sales>,  :birthday(Date.new('1981-03-21')));

is $t6.process('simple-nest', :users(@users)), $wanted, 'Nested data with array of objects';

