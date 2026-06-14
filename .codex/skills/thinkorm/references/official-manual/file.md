简介
ThinkORM是一个基于PHP和PDO的数据库中间层和ORM类库，早期作为ThinkPHP的一个核心组件现已独立出来，以优异的功能和突出的性能著称，提供了更优秀的性能和开发体验，最新版本要求PHP8.0+。

本手册的内容主要针对3.0+版本，2.0和3.0版本功能差别不大，主要是底层的PHP版本依赖不同，3.0+版本采用PHP8.0重构。

本手册内容主要针对独立使用ThinkORM的情况，如果你只是在ThinkPHP6.0+中使用，可以参考ThinkPHP官方手册的数据库和模型章节部分即可。

主要特性：
基于PDO和PHP强类型实现
支持原生查询和查询构造器
自动参数绑定和预查询
简洁易用的查询功能
强大灵活的模型用法
支持预载入关联查询和延迟关联查询
支持多数据库及动态切换
支持MongoDb
支持分布式及事务
支持断点重连
支持JSON查询
支持数据库日志
支持PSR-16缓存及PSR-3日志规范
如果需要连接池功能，请直接使用think-swoole扩展。

环境要求
3.0版本：PHP8.0+ / 2.0版本：PHP7.1+

安装
使用composer安装

composer require topthink/think-orm
最新的3.0版本要求PHP8.0+，如果你的PHP环境低于8.0，可以安装2.0版本。
数据库配置
数据库配置
如果你是独立使用，首先需要配置数据库的连接参数，使用如下方式：

use think\facade\Db;
// 数据库配置信息设置（全局有效）
Db::setConfig([
// 默认数据连接标识
'default' => 'mysql',
// 数据库连接信息
'connections' => [
'mysql' => [
// 数据库类型
'type' => 'mysql',
// 主机地址
'hostname' => '127.0.0.1',
// 用户名
'username' => 'root',
// 数据库名
'database' => 'demo',
// 数据库编码默认采用utf8
'charset' => 'utf8',
// 数据库表前缀
'prefix' => 'think_',
// 数据库调试模式
'debug' => true,
],
],
]);
如果你在ThinkPHP6.0+使用的话，无需动态设置，直接在database.php数据库配置文件中按如下方式定义即可。

return [
'default' => 'mysql',
'connections' => [
'mysql' => [
// 数据库类型
'type' => 'mysql',
// 服务器地址
'hostname' => '127.0.0.1',
// 数据库名
'database' => 'thinkphp',
// 数据库用户名
'username' => 'root',
// 数据库密码
'password' => '',
// 数据库连接端口
'hostport' => '',
// 数据库连接参数
'params' => [],
// 数据库编码默认采用utf8
'charset' => 'utf8',
// 数据库表前缀
'prefix' => 'think\_',
],
],
];
当然在ThinkPHP里面可以使用环境变量来定义数据库连接配置信息

配置参数
数据库配置支持多个数据库连接，而default配置用于设置默认使用的数据库连接配置。connections则配置具体的数据库连接信息，default配置参数定义的连接配置必须要存在。

下面是默认支持的数据库连接参数：

参数名 描述 默认值
type 数据库类型 无
hostname 数据库地址 127.0.0.1
database 数据库名称 无
username 数据库用户名 无
password 数据库密码 无
hostport 数据库端口号 无
dsn 数据库连接dsn信息 无
params 数据库连接参数 空
charset 数据库编码 utf8
prefix 数据库的表前缀 无
deploy 数据库部署方式:0 集中式(单一服务器),1 分布式(主从服务器) 0
rw_separate 数据库读写是否分离 主从式有效 false
master_num 读写分离后 主服务器数量 1
slave_no 指定从服务器序号 无
fields_strict 是否严格检查字段是否存在 true
auto_timestamp 自动写入时间戳字段 false
break_reconnect 是否开启断线重连 false
fields_cache 是否开启字段缓存 false
schema_cache_path 字段缓存目录 无
trigger_sql 是否开启SQL监听（日志） true
query 指定查询对象 think\db\Query
type参数用于指定数据库类型，内置支持的类型包括：

type 数据库
mysql MySQL
sqlite SqLite
pgsql PostgreSQL
sqlsrv SqlServer
mongo MongoDb
oracle Oracle
除了以上内置的数据库类型之外，你可以自己扩展数据库连接类型，通常在这种情况下，type配置就是你的数据库连接对象类名。

常用数据库连接参数（params）可以参考PHP在线手册中的以PDO::ATTR\_开头的常量。

dsn配置可用于一些自定义的高级连接参数，例如：

'dsn' => 'mysql:dbname=testdb;host=127.0.0.1'
如果同时定义了参数化数据库连接信息和dsn配置，则会优先使用dsn配置参数定义的数据库连接信息。

如果是使用pgsql数据库驱动的话，请先导入 db/connector/pgsql.sql文件到数据库执行。
分布式数据库
分布式支持
数据访问层支持分布式数据库，包括读写分离，要启用分布式数据库，需要开启数据库配置文件中的deploy参数：

'default' => 'mysql',
'connections' => [
'mysql' => [
// 启用分布式数据库
'deploy' => 1,
// 数据库类型
'type' => 'mysql',
// 服务器地址
'hostname' => '192.168.1.1,192.168.1.2',
// 数据库名
'database' => 'demo',
// 数据库用户名
'username' => 'root',
// 数据库密码
'password' => '',
// 数据库连接端口
'hostport' => '',
],
],
启用分布式数据库后，hostname参数是关键，hostname的个数决定了分布式数据库的数量，默认情况下第一个地址就是主服务器。

主从服务器支持设置不同的连接参数，包括：

连接参数
username
password
hostport
database
dsn
charset
如果主从服务器的上述参数一致的话，只需要设置一个，对于不同的参数，可以分别设置，例如：

'default' => 'mysql',
'connections' => [
'mysql' => [
// 启用分布式数据库
'deploy' => 1,
// 数据库类型
'type' => 'mysql',
// 服务器地址
'hostname' => '192.168.1.1,192.168.1.2,192.168.1.3',
// 数据库名
'database' => 'demo',
// 数据库用户名
'username' => 'root,slave,slave',
// 数据库密码
'password' => '123456',
// 数据库连接端口
'hostport' => '',
// 数据库字符集
'charset' => 'utf8',
],
],
记住，要么相同，要么每个都要设置。

分布式的数据库参数支持使用数组定义（通常为了避免多个账号和密码的误解析），例如：

'default' => 'mysql',
'connections' => [
'mysql' => [
// 启用分布式数据库
'deploy' => 1,
// 数据库类型
'type' => 'mysql',
// 服务器地址
'hostname' =>[ '192.168.1.1','192.168.1.2','192.168.1.3'],
// 数据库名
'database' => 'demo',
// 数据库用户名
'username' => 'root,slave,slave',
// 数据库密码
'password' => ['123456','abc,def','hello']
// 数据库连接端口
'hostport' => '',
// 数据库字符集
'charset' => 'utf8',
],
],
读写分离
还可以设置分布式数据库的读写是否分离，默认的情况下读写不分离，也就是每台服务器都可以进行读写操作，对于主从式数据库而言，需要设置读写分离，通过下面的设置就可以：

'rw_separate' => true,
在读写分离的情况下，默认第一个数据库配置是主服务器的配置信息，负责写入数据，如果设置了master_num参数，则可以支持多个主服务器写入（每次随机连接其中一个主服务器）。其它的地址都是从数据库，负责读取数据，数量不限制。每次连接从服务器并且进行读取操作的时候，系统会随机进行在从服务器中选择。同一个数据库连接的每次请求只会连接一次主服务器和从服务器，如果某次请求的从服务器连接不上，会自动切换到主服务器进行查询操作。

如果不希望随机读取，或者某种情况下其它从服务器暂时不可用，还可以设置slave_no 指定固定服务器进行读操作，slave_no指定的序号表示hostname中数据库地址的序号，从0开始。

调用查询类或者模型的CURD操作的话，系统会自动判断当前执行的方法是读操作还是写操作并自动连接主从服务器，如果你用的是原生SQL，那么需要注意系统的默认规则： 写操作必须用数据库的execute方法，读操作必须用数据库的query方法，否则会发生主从读写错乱的情况。

发生下列情况的话，会自动连接主服务器：

使用了数据库的写操作方法（execute/insert/update/delete以及衍生方法）；
如果调用了数据库事务方法的话，会自动连接主服务器；
从服务器连接失败，会自动连接主服务器；
调用了查询构造器的lock方法；
调用了查询构造器的master方法
配置开启了read_master参数，并且执行了写入操作，则后续该表所有的查询都会连接主服务器
如果在大数据量或者特殊的情况下写入数据后可能会存在同步延迟的情况，可以调用master()方法进行主库查询操作。

在实际生产环境中，很多云主机的数据库分布式实现机制和本地开发会有所区别，但通常会采下面用两种方式：

第一种：提供了写IP和读IP（一般是虚拟IP），进行数据库的读写分离操作；
第二种：始终保持同一个IP连接数据库，内部会进行读写分离IP调度（阿里云就是采用该方式）。
主库读取
有些情况下，需要直接从主库读取数据，例如刚写入数据之后，从库数据还没来得及同步完成，你可以使用

Db::name('user')
->where('id', 1)
->update(['name' => 'thinkphp']);
Db::name('user')
->master(true)
->find(1);
不过，实际情况远比这个要复杂，因为你并不清楚后续的方法里面是否还存在相关查询操作，这个时候我们可以配置开启数据库的read_master配置参数。

// 开启自动主库读取
'read_master' => true,
开启后，一旦我们对某个数据表进行了写操作，那么当前请求的后续所有对该表的查询都会使用主库读取。
查询数据
本篇给出了基本的查询用法，更多的查询用法可以参考后续的章节。

查询单个数据
查询单个数据使用find方法：

// table方法必须指定完整的数据表名
Db::table('think_user')->where('id', 1)->find();
// 如果设置了数据表前缀（prefix）参数的话 也可以使用
Db::name('user')->where('id', 1)->find();
即使满足条件的数据有多个，find查询也只会返回一条数据。你可以使用order排序来决定返回某一条数据。

最终生成的SQL语句可能是（本手册中的示例如未说明均以MySql作为示例）：

SELECT \* FROM `think_user` WHERE `id` = 1 LIMIT 1
find 方法查询结果不存在，返回 null，否则返回结果数组

如果希望查询数据不存在的时候返回空数组，可以使用

// table方法必须指定完整的数据表名
Db::table('think_user')->where('id', 1)->findOrEmpty();
如果希望在没有找到数据后抛出异常可以使用

Db::table('think_user')->where('id', 1)->findOrFail();
如果没有查找到数据，则会抛出一个 think\db\exception\DataNotFoundException 异常。

find方法可以传入闭包，当没有查询到数据的时候会执行闭包返回。

Db::table('think_user')->where('id', 1)->find(function(Query $query){
// 执行其它查询操作并返回
// return $query->where()->find();
});
查询数据集
查询多个数据（数据集）使用select方法：

$list = Db::table('think_user')->where('status', 1)->select();

foreach ($list as $user) {
echo $user['name'];
}
最终生成的SQL语句可能是：

SELECT \* FROM `think_user` WHERE `status` = 1
select 方法查询结果是一个数据集对象（think\Collection），如果需要转换为（二维）数组可以使用

$list = Db::table('think_user')->where('status', 1)->select()->toArray();

foreach ($list as $user) {
echo $user['name'];
}
但通常这是没有必要的，因为数据集对象的操作和数组是几乎一致的。

如果希望在没有查找到数据后抛出异常可以使用

Db::table('think_user')->where('status',1)->selectOrFail();
如果没有查找到数据，同样也会抛出一个 think\db\exception\DataNotFoundException 异常。

如果设置了数据表前缀参数的话，可以使用

Db::name('user')->where('id', 1)->find();
Db::name('user')->where('status', 1)->select();
如果你的数据表没有设置表前缀的话，那么name和table方法效果一致。

示例只是使用了简单的where方法，其实在find和select方法之前可以使用更多的链式操作（参考后面链式操作章节）方法以完成更多的查询条件。

数据集
数据库的select查询结果默认返回数据集对象（think\Collection），提供了和数组无差别用法，并且另外封装了一些额外的方法。

// 获取数据集
$users = Db::name('user')->select();
// 遍历数据集
foreach($users as $user){
echo $user['name'];
echo $user['id'];
}
可以直接使用数组的方式操作数据集对象，例如：

// 获取数据集
$users = Db::name('user')->select();
// 直接操作第一个元素
$item = $users[0];
// 获取数据集记录数
$count = count($users);
// 遍历数据集
foreach($users as $user){
echo $user['name'];
echo $user['id'];
}
需要注意的是，如果要判断数据集是否为空，不能直接使用empty判断，而必须使用数据集对象的isEmpty方法判断，例如：

$users = Db::name('user')->select();
if($users->isEmpty()){
echo '数据集为空';
}
think\Collection类包含了下列主要方法：

方法 描述
isEmpty 是否为空
toArray 转换为数组
all 所有数据
merge 合并其它数据
diff 比较数组，返回差集
flip 交换数据中的键和值
intersect 比较数组，返回交集
keys 返回数据中的所有键名
first 返回第一个元素
last 返回最后一个元素
pop 删除数据中的最后一个元素
shift 删除数据中的第一个元素
unshift 在数据开头插入一个元素
push 在结尾插入一个元素
reduce 通过使用用户自定义函数，以字符串返回数组
reverse 数据倒序重排
chunk 数据分隔为多个数据块
each 给数据的每个元素执行回调
filter 用回调函数过滤数据中的元素
column 返回数据中的指定列
sort 对数据排序
order 指定字段排序
shuffle 将数据打乱
slice 截取数据中的一部分
map 用回调函数处理数组中的元素
where 根据字段条件过滤数组中的元素
whereLike Like查询过滤元素
whereNotLike Not Like过滤元素
whereIn IN查询过滤数组中的元素
whereNotIn Not IN查询过滤数组中的元素
whereBetween Between查询过滤数组中的元素
whereNotBetween Not Between查询过滤数组中的元素
值和列查询
查询某个字段的值可以用

// 返回某个字段的值
Db::table('think_user')->where('id', 1)->value('name');
value方法查询结果不存在，返回 null

查询某一列的值可以用

// 返回数组
Db::table('think_user')->where('status',1)->column('name');
// 指定id字段的值作为索引
Db::table('think_user')->where('status',1)->column('name', 'id');
如果要返回完整数据，并且添加一个索引值的话，可以使用

// 指定id字段的值作为索引 返回所有数据
Db::table('think_user')->where('status',1)->column('\*','id');
column 方法查询结果不存在，返回空数组

数据分批处理
如果你需要处理成千上百条数据库记录，可以考虑使用chunk方法，该方法一次获取结果集的一小块，然后填充每一小块数据到要处理的闭包，该方法在编写处理大量数据库记录的时候非常有用。

比如，我们可以全部用户表数据进行分批处理，每次处理 100 个用户记录：

Db::table('think_user')->chunk(100, function($users) {
    foreach ($users as $user) {
// 对100条用户数据进行处理操作
}
});
你可以通过从闭包函数中返回false来中止对后续数据集的处理：

Db::table('think_user')->chunk(100, function($users) {
    foreach ($users as $user) {
        // 处理结果集...
		if($user->status == 0){
return false;
}
}
});
也支持在chunk方法之前调用其它的查询方法，例如：

Db::table('think_user')
->where('score','>',80)
->chunk(100, function($users) {
    foreach ($users as $user) {
//
}
});
chunk方法的处理默认是根据主键查询，支持指定字段，例如：

Db::table('think_user')->chunk(100, function($users) {
// 处理结果集...
return false;
},'create_time');
并且支持指定处理数据的顺序。

Db::table('think_user')->chunk(100, function($users) {
// 处理结果集...
return false;
},'create_time', 'desc');
chunk方法一般用于命令行操作批处理数据库的数据，不适合WEB访问处理大量数据，很容易导致超时。

游标查询
如果你需要处理大量的数据，可以使用游标查询功能，该查询方式利用了PHP的生成器特性，可以大幅减少大量数据查询的内存开销问题。

$list = Db::name('user')->where('status', 1)->cursor();
foreach($list as $user){
echo $user['name'];
}
cursor方法返回的是一个生成器对象，user变量是数据表的一条数据（数组）。
新增数据
添加一条数据
可以使用save方法统一写入数据，自动判断是新增还是更新数据（以写入数据中是否存在主键数据为依据）。

$data = ['foo' => 'bar', 'bar' => 'foo'];
Db::name('user')->save($data);
如果你的数据中包含主键数据，可以传入第二个参数强制新增数据。

$data = ['id' => 1, 'foo' => 'bar', 'bar' => 'foo'];
Db::name('user')->save($data, true);
或者使用 insert 方法向数据库明确新增一条数据

$data = ['foo' => 'bar', 'bar' => 'foo'];
Db::name('user')->insert($data);
insert 或者save方法添加数据成功返回添加成功的条数，通常情况返回 1

默认情况下查询构造器使用严格模式，也就是说如果你的数据表里面没有foo或者bar字段，那么就会抛出异常。如果不希望抛出异常，可以通过下面的方法关闭严格模式：

$data = ['foo' => 'bar', 'bar' => 'foo'];
Db::name('user')->strict(false)->insert($data);
不存在字段的值将会直接抛弃。如果你希望全局关闭严格模式，那么可以修改数据库的配置参数

// 关闭严格模式
'fields_strict' => false
如果是MySQL数据库，支持replace方式写入，例如：

$data = ['foo' => 'bar', 'bar' => 'foo'];
Db::name('user')->replace()->insert($data);
如果你的数据表采用了自增主键，并且添加数据后如果需要返回新增数据的自增主键，可以使用insertGetId方法新增数据并返回主键值：

$userId = Db::name('user')->insertGetId($data);
insertGetId 方法添加数据成功返回添加数据的自增主键

添加多条数据
添加多条数据直接使用 insertAll 方法传入需要添加的数据（通常是二维数组）即可。

$data = [
    ['foo' => 'bar', 'bar' => 'foo'],
    ['foo' => 'bar1', 'bar' => 'foo1'],
    ['foo' => 'bar2', 'bar' => 'foo2']
];
Db::name('user')->insertAll($data);
insertAll 方法添加数据成功返回添加成功的条数

如果是mysql数据库，支持replace写入，例如：

$data = [
    ['foo' => 'bar', 'bar' => 'foo'],
    ['foo' => 'bar1', 'bar' => 'foo1'],
    ['foo' => 'bar2', 'bar' => 'foo2']
];
Db::name('user')->replace()->insertAll($data);
确保要批量添加的数据字段是一致的

如果批量插入的数据比较多，可以指定分批插入，使用limit方法指定每次插入的数量限制。

$data = [
    ['foo' => 'bar', 'bar' => 'foo'],
    ['foo' => 'bar1', 'bar' => 'foo1'],
    ['foo' => 'bar2', 'bar' => 'foo2']
    ...
];
// 分批写入 每次最多1000条数据
Db::name('user')
    ->limit(1000)
    ->insertAll($data);
如果写入的数据量比较大，会自动分成多个语句执行写入，每次最多写入1000条数据。
更新数据
更新数据
可以使用save方法更新数据

Db::name('user')
->save(['id' => 1, 'name' => 'thinkphp']);
save方法会自动判断是新增数据还是更新数据，主要是判断数据中是否包含主键数据。

或者使用update方法。

Db::name('user')
->update(['id' => 1, 'name' => 'thinkphp']);
实际生成的SQL语句可能是：

UPDATE `think_user` SET `name`='thinkphp' WHERE `id` = 1
更新的数据必须包含主键，否则需要指定更新条件，例如：

Db::name('user')
->where('id' ,1)
->update(['name' => 'thinkphp']);
update 方法返回影响数据的条数，没修改任何数据返回 0

支持使用data方法传入要更新的数据

Db::name('user')
->where('id', 1)
->data(['name' => 'thinkphp'])
->update();
如果update方法和data方法同时传入更新数据，则以update方法为准。

如果要更新的数据需要使用SQL函数或者其它字段，可以使用下面的方式：

Db::name('user')
->where('id',1)
->exp('name','UPPER(name)')
->update();
实际生成的SQL语句：

UPDATE `think_user` SET `name` = UPPER(name) WHERE `id` = 1
支持使用raw助手函数进行数据更新。

Db::name('user')
->where('id', 1)
->update([
'name' => raw('UPPER(name)'),
'score' => raw('score-3'),
'read_time' => raw('read_time+1')
]);
自增/自减
如果要更新的字段是数值类型，可以使用inc/dec方法自增或自减一个字段的值（ 如不加第二个参数，默认步长为1）。

// score 字段加 1
Db::name('user')
->where('id', 1)
->inc('score')
->update();

// score 字段加 5
Db::name('user')
->where('id', 1)
->inc('score', 5)
->update();

// score 字段减 1
Db::name('user')
->where('id', 1)
->dec('score')
->update();

// score 字段减 5
Db::name('user')
->where('id', 1)
->dec('score', 5)
->update();
最终生成的SQL语句可能是：

UPDATE `think_user` SET `score` = `score` + 1 WHERE `id` = 1
UPDATE `think_user` SET `score` = `score` + 5 WHERE `id` = 1
UPDATE `think_user` SET `score` = `score` - 1 WHERE `id` = 1
UPDATE `think_user` SET `score` = `score` - 5 WHERE `id` = 1
延时写入
对于一些实时性要求不高的但调用频率比较高的可以使用setInc/setDec方法延时更新写入（单位为秒）。

// read_count 字段加 1 延时更新600秒
Db::name('blog')
->where('id', 1)
->setInc('read_count', 1, 600)
删除数据
删除数据
// 根据主键删除
Db::table('think_user')->delete(1);
Db::table('think_user')->delete([1, 2, 3]);

// 条件删除  
Db::table('think_user')->where('id', 1)->delete();
Db::table('think_user')->where('id', '<', 10)->delete();
最终生成的SQL语句可能是：

DELETE FROM `think_user` WHERE `id` = 1
DELETE FROM `think_user` WHERE `id` IN (1,2,3)
DELETE FROM `think_user` WHERE `id` = 1
DELETE FROM `think_user` WHERE `id` < 10
delete 方法返回影响数据的条数，没有删除任何数据返回 0

出于安全考虑，如果不带任何条件调用delete方法会提示错误，如果你确实需要删除所有数据，可以使用

// 无条件删除所有数据
Db::name('user')->delete(true);
最终生成的SQL语句是（删除了表的所有数据）：

DELETE FROM `think_user`
一般情况下，业务数据不建议真实删除数据，系统提供了软删除机制（模型中使用软删除更为方便）。

// 软删除数据 使用delete_time字段标记删除
Db::name('user')
->where('id', 1)
->useSoftDelete('delete_time',time())
->delete();
实际生成的SQL语句可能如下（执行的是UPDATE操作）：

UPDATE `think_user` SET `delete_time` = '1515745214' WHERE `id` = 1
useSoftDelete方法表示使用软删除，并且指定软删除字段为delete_time，写入数据为当前的时间戳。
链式操作
数据库提供的链式操作方法，可以有效的提高数据存取的代码清晰度和开发效率，并且支持所有的CURD操作（原生查询方法query、execute等方法不支持链式操作）。

使用也比较简单，假如我们现在要查询一个User表的满足状态为1的前10条记录，并希望按照用户的创建时间排序 ，代码如下：

Db::table('think_user')
->where('status',1)
->order('create_time')
->limit(10)
->select();

﻿
这里的where、order和limit方法就被称之为链式操作方法，除了select方法必须放到最后一个外（因为select方法并不是链式操作方法），链式操作的方法调用顺序没有先后，例如，下面的代码和上面的等效：

Db::table('think_user')
->order('create_time')
->limit(10)
->where('status',1)
->select();

﻿
其实不仅仅是查询方法可以使用连贯操作，包括所有的CURD方法都可以使用，例如：

Db::table('think_user')
->where('id',1)
->field('id,name,email')
->find();

Db::table('think_user')
->where('status',1)
->where('id',1)
->delete();

﻿
每次Db类的静态方法调用是创建一个新的查询对象实例，如果你需要多次复用使用链式操作值，可以使用下面的方法。

$user = Db::table('user');
$user->order('create_time')
->where('status',1)
->select();

// 会自动带上前面的where条件和order排序的值  
$user->count();
当前查询对象在查询之后仍然会保留链式操作的值，除非你调用removeOption方法清空链式操作的值。

$user = Db::table('think_user');
$user->order('create_time')
->where('status',1)
->select();

// 清空where查询条件值 保留其它链式操作  
$user->removeOption('where')
->where('id', '>', 0)
->select();

﻿
常用的链式操作方法包含：

连贯操作 作用 支持的参数类型
where* 用于AND查询 字符串、数组和对象
whereOr* 用于OR查询 字符串、数组和对象
whereTime* 用于时间日期的快捷查询 字符串
table 用于定义要操作的数据表名称 字符串和数组
alias 用于给当前数据表定义别名 字符串
field* 用于定义要查询的字段（支持字段排除） 字符串和数组
order* 用于对结果排序 字符串和数组
limit 用于限制查询结果数量 字符串和数字
page 用于查询分页（内部会转换成limit） 字符串和数字
group 用于对查询的group支持 字符串
having 用于对查询的having支持 字符串
join* 用于对查询的join支持 字符串和数组
union* 用于对查询的union支持 字符串、数组和对象
view* 用于视图查询 字符串、数组
distinct 用于查询的distinct支持 布尔值
lock 用于数据库的锁机制 布尔值
cache 用于查询缓存 支持多个参数
comment 用于SQL注释 字符串
force 用于数据集的强制索引 字符串
master 用于设置主服务器读取数据 布尔值
strict 用于设置是否严格检测字段名是否存在 布尔值
sequence 用于设置自增序列名 字符串
failException 用于设置没有查询到数据是否抛出异常 布尔值
partition 用于设置分区信息 数组 字符串
replace 用于设置使用REPLACE方式写入 布尔值
extra 用于设置额外查询规则 字符串
duplicate 用于设置DUPLCATE信息 数组 字符串

﻿
所有的连贯操作都返回当前的模型实例对象（this），其中带\*标识的表示支持多次调用。
Where
where方法在链式操作方法里面是最常用的方法，可以完成包括普通查询、表达式查询、快捷查询、区间查询、组合查询在内的条件查询操作。

where方法的用法很多，这里主要描述下最常用的表达式查询用法，更多的查询请参考高级查询章节及后续章节。

表达式查询
表达式查询是官方推荐使用的查询方式

查询表达式支持大部分的SQL查询语法，也是ThinkORM查询语言的精髓，查询表达式的使用格式：

where('字段名', '查询表达式', '查询条件');

除了where方法外，还可以支持whereOr，用法是一样的。为了更加方便查询，大多数的查询表达式都提供了快捷查询方法。

表达式不分大小写，支持的查询表达式有下面几种：

表达式 含义 快捷查询方法
= 等于
<> 不等于

>     大于
>
> = 大于等于
> < 小于
> <= 小于等于
> [NOT] LIKE 模糊查询 whereLike/whereNotLike
> [NOT] BETWEEN （不在）区间查询 whereBetween/whereNotBetween
> [NOT] IN （不在）IN 查询 whereIn/whereNotIn
> [NOT] NULL 查询字段是否（不）是NULL whereNull/whereNotNull
> [NOT] EXISTS EXISTS查询 whereExists/whereNotExists
> [NOT] REGEXP 正则（不）匹配查询（仅支持Mysql）
> [NOT] BETWEEM TIME 时间区间比较 whereBetweenTime
> TIME 大于某个时间 whereTime
> < TIME 小于某个时间 whereTime
> = TIME 大于等于某个时间 whereTime
> <= TIME 小于等于某个时间 whereTime
> EXP 表达式查询，支持SQL语法 whereExp
> find in set FIND_IN_SET查询 whereFindInSet
> 表达式查询的用法示例如下：

等于（=）
例如：

Db::name('user')->where('id','=',100)->select();
和下面的查询等效

Db::name('user')->where('id',100)->select();
最终生成的SQL语句是：

SELECT \* FROM `think_user` WHERE `id` = 100
不等于（<>）
例如：

Db::name('user')->where('id','<>',100)->select();
最终生成的SQL语句是：

SELECT \* FROM `think_user` WHERE `id` <> 100
大于（>）
例如：

Db::name('user')->where('id','>',100)->select();
最终生成的SQL语句是：

SELECT \* FROM `think_user` WHERE `id` > 100
大于等于（>=）
例如：

Db::name('user')->where('id','>=',100)->select();
最终生成的SQL语句是：

SELECT \* FROM `think_user` WHERE `id` >= 100
小于（<）
例如：

Db::name('user')->where('id', '<', 100)->select();
最终生成的SQL语句是：

SELECT \* FROM `think_user` WHERE `id` < 100
小于等于（<=）
例如：

Db::name('user')->where('id', '<=', 100)->select();
最终生成的SQL语句是：

SELECT \* FROM `think_user` WHERE `id` <= 100
[NOT] LIKE： 同sql的LIKE
例如：

Db::name('user')->where('name', 'like', 'thinkphp%')->select();
最终生成的SQL语句是：

SELECT \* FROM `think_user` WHERE `name` LIKE 'thinkphp%'
like查询支持使用数组

Db::name('user')->where('name', 'like', ['%think','php%'],'OR')->select();
实际生成的SQL语句为：

SELECT \* FROM `think_user` WHERE (`name` LIKE '%think' OR `name` LIKE 'php%')
为了更加方便，应该直接使用whereLike方法

Db::name('user')->whereLike('name','thinkphp%')->select();
Db::name('user')->whereNotLike('name','thinkphp%')->select();
whereLike查询同样也支持使用数组

Db::name('user')->whereLike('name', ['%think','php%'], 'OR')->select();
[NOT] BETWEEN ：同sql的[not] between
查询条件支持字符串或者数组，例如：

Db::name('user')->where('id','between','1,8')->select();
和下面的等效：

Db::name('user')->where('id','between',[1,8])->select();
最终生成的SQL语句都是：

SELECT \* FROM `think_user` WHERE `id` BETWEEN 1 AND 8
或者使用快捷查询方法：

Db::name('user')->whereBetween('id','1,8')->select();
Db::name('user')->whereNotBetween('id','1,8')->select();
[NOT] IN： 同sql的[not] in
查询条件支持字符串或者数组，例如：

Db::name('user')->where('id','in','1,5,8')->select();
和下面的等效：

Db::name('user')->where('id','in',[1,5,8])->select();
最终的SQL语句为：

SELECT \* FROM `think_user` WHERE `id` IN (1,5,8)
或者使用快捷查询方法：

Db::name('user')->whereIn('id','1,5,8')->select();
Db::name('user')->whereNotIn('id','1,5,8')->select();
[NOT] IN查询支持使用闭包方式

Db::name('user')->whereIn('id', function($query) {
return $query->name('profile')->field('user_id')->where('score', '>', 80);
})->select();
[NOT] NULL ：
查询字段是否（不）是Null，例如：

Db::name('user')->where('name', null)
->where('email','null')
->where('name','not null')
->select();
实际生成的SQL语句为：

SELECT \* FROM `think_user` WHERE `name` IS NULL AND `email` IS NULL AND `name` IS NOT NULL
如果你需要查询一个字段的值为字符串null或者not null，应该使用：

Db::name('user')->where('title','=', 'null')
->where('name','=', 'not null')
->select();
推荐的方式是使用whereNull和whereNotNull方法查询。

Db::name('user')->whereNull('name')
->whereNull('email')
->whereNotNull('name')
->select();
EXP：表达式
支持更复杂的查询情况 例如：

Db::name('user')->where('id','in','1,3,8')->select();
可以改成：

Db::name('user')->where('id','exp',' IN (1,3,8) ')->select();
exp查询的条件不会被当成字符串，所以后面的查询条件可以使用任何SQL支持的语法，包括使用函数和字段名称。

推荐使用whereExp方法查询

Db::name('user')->whereExp('id', 'IN (1,3,8) ')->select();
Table
table方法主要用于指定操作的数据表。

用法
一般情况下，操作模型的时候系统能够自动识别当前对应的数据表，所以，使用table方法的情况通常是为了：

切换操作的数据表；
对多表进行操作；
例如：

Db::table('think_user')->where('status', 1)->select();
也可以在table方法中指定数据库，例如：

Db::table('db_name.think_user')->where('status', 1)->select();
table方法指定的数据表需要完整的表名，但可以采用name方式简化数据表前缀的传入，例如：

Db::name('user')->where('status', 1)->select();
会自动获取当前模型对应的数据表前缀来生成 think_user 数据表名称。

需要注意的是table方法不会改变数据库的连接，所以你要确保当前连接的用户有权限操作相应的数据库和数据表。

如果需要对多表进行操作，可以这样使用：

Db::field('user.name,role.title')
->table('think_user user,think_role role')
->limit(10)->select();
为了尽量避免和mysql的关键字冲突，可以建议使用数组方式定义，例如：

Db::field('user.name,role.title')
->table([
'think_user'=>'user',
'think_role'=>'role'
])
->limit(10)->select();
使用数组方式定义的优势是可以避免因为表名和关键字冲突而出错的情况。

如果你的表名是特殊的子查询构建的，建议使用tableRaw方法
Alias
alias用于设置当前数据表的别名，便于使用其他的连贯操作例如join方法等。

示例：

Db::table('think_user')
->alias('a')
->join('think_dept b ','b.user_id= a.id')
->select();
最终生成的SQL语句类似于：

SELECT \* FROM think_user a INNER JOIN think_dept b ON b.user_id= a.id
可以传入数组批量设置数据表以及别名，例如：

Db::table('think_user')
->alias(['think_user'=>'user','think_dept'=>'dept'])
->join('think_dept','dept.user_id= user.id')
->select();
最终生成的SQL语句类似于：

SELECT \* FROM think_user user INNER JOIN think_dept dept ON dept.user_id= user.id
Field
field方法主要作用是标识要返回或者操作的字段，可以用于查询和写入操作。

用于查询
指定字段
在查询操作中field方法是使用最频繁的。

Db::table('user')->field('id,title,content')->select();
这里使用field方法指定了查询的结果集中包含id,title,content三个字段的值。执行的SQL相当于：

SELECT id,title,content FROM user
可以给某个字段设置别名，例如：

Db::table('user')->field('id,nickname as name')->select();
执行的SQL语句相当于：

SELECT id,nickname as name FROM user
使用SQL函数
可以在fieldRaw方法中直接使用函数，例如：

Db::table('user')->fieldRaw('id,SUM(score)')->select();
执行的SQL相当于：

SELECT id,SUM(score) FROM user
除了select方法之外，所有的查询方法，包括find等都可以使用field方法。

使用数组参数
field方法的参数可以支持数组，例如：

Db::table('user')->field(['id','title','content'])->select();
最终执行的SQL和前面用字符串方式是等效的。

数组方式的定义可以为某些字段定义别名，例如：

Db::table('user')->field(['id','nickname'=>'name'])->select();
执行的SQL相当于：

SELECT id,nickname as name FROM user
获取所有字段
如果有一个表有非常多的字段，需要获取所有的字段（这个也许很简单，因为不调用field方法或者直接使用空的field方法都能做到）：

Db::table('user')->select();
Db::table('user')->field('\*')->select();
上面的用法是等效的，都相当于执行SQL：

SELECT \* FROM user
但是这并不是我说的获取所有字段，而是显式的调用所有字段（对于对性能要求比较高的系统，这个要求并不过分，起码是一个比较好的习惯），下面的用法可以完成预期的作用：

Db::table('user')->field(true)->select();
field(true)的用法会显式的获取数据表的所有字段列表，哪怕你的数据表有100个字段。

字段排除
如果我希望获取排除数据表中的content字段（文本字段的值非常耗内存）之外的所有字段值，我们就可以使用field方法的排除功能，例如下面的方式就可以实现所说的功能：

Db::table('user')->withoutField('content')->select();
则表示获取除了content之外的所有字段，要排除更多的字段也可以：

Db::table('user')->withoutField('user_id,content')->select();
//或者用
Db::table('user')->withoutField(['user_id','content'])->select();
注意的是 字段排除功能不支持跨表和join操作。

用于写入
除了查询操作之外，field方法还有一个非常重要的安全功能--字段合法性检测。field方法结合数据库的写入方法使用就可以完成表单提交的字段合法性检测，如果我们在表单提交的处理方法中使用了：

Db::table('user')->field('title,email,content')->insert($data);
即表示表单中的合法字段只有title,email和content字段，无论用户通过什么手段更改或者添加了浏览器的提交字段，都会直接屏蔽。因为，其他所有字段我们都不希望由用户提交来决定，你可以通过自动完成功能定义额外需要自动写入的字段。

在开启数据表字段严格检查的情况下，提交了非法字段会抛出异常，可以在数据库设置文件中设置：

// 关闭严格字段检查
'fields_strict' => false,
Strict
strict方法用于设置是否严格检查字段名，用法如下：

// 关闭字段严格检查
Db::name('user')
->strict(false)
->insert($data);
注意，系统默认值是由数据库配置参数fields_strict决定，因此修改数据库配置参数可以进行全局的严格检查配置，如下：

// 关闭严格检查字段是否存在
'fields_strict' => false,
如果开启字段严格检查的话，在更新和写入数据库的时候，一旦存在非数据表字段的值，则会抛出异常。
Limit
limit方法主要用于指定查询和操作的数量。

limit方法可以兼容所有的数据库驱动类的

限制结果数量
例如获取满足要求的10个用户，如下调用即可：

Db::table('user')
->where('status',1)
->field('id,name')
->limit(10)
->select();
limit方法也可以用于写操作，例如更新满足要求的3条数据：

Db::table('user')
->where('score',100)
->limit(3)
->update(['level'=>'A']);
限制每次最大写入数量
如果用于insertAll方法的话，则可以分批多次写入，每次最多写入limit方法指定的数量。

Db::table('user')
->limit(100)
->insertAll($userList);
分页查询
用于文章分页查询是limit方法比较常用的场合，例如：

Db::table('article')->limit(10, 25)->select();
表示查询文章数据，从第10行开始的25条数据（可能还取决于where条件和order排序的影响 这个暂且不提）。

对于大数据表，尽量使用limit限制查询结果，否则会导致很大的内存开销和性能问题。
Page
page方法主要用于分页查询。

我们在前面已经了解了关于limit方法用于分页查询的情况，而page方法则是更人性化的进行分页查询的方法，例如还是以文章列表分页为例来说，如果使用limit方法，我们要查询第一页和第二页（假设我们每页输出10条数据）写法如下：

// 查询第一页数据
Db::table('article')->limit(0,10)->select();
// 查询第二页数据
Db::table('article')->limit(10,10)->select();
虽然利用扩展类库中的分页类Page可以自动计算出每个分页的limit参数，但是如果要自己写就比较费力了，如果用page方法来写则简单多了，例如：

// 查询第一页数据
Db::table('article')->page(1,10)->select();
// 查询第二页数据
Db::table('article')->page(2,10)->select();
显而易见的是，使用page方法你不需要计算每个分页数据的起始位置，page方法内部会自动计算。

page方法还可以和limit方法配合使用，例如：

Db::table('article')->limit(25)->page(3)->select();
当page方法只有一个值传入的时候，表示第几页，而limit方法则用于设置每页显示的数量，也就是说上面的写法等同于：

Db::table('article')->page(3,25)->select();
Order
order方法用于对操作的结果排序或者优先级限制。

用法如下：

Db::table('user')
->where('status', 1)
->order('id', 'desc')
->limit(5)
->select();
SELECT \* FROM `user` WHERE `status` = 1 ORDER BY `id` desc LIMIT 5
如果没有指定desc或者asc排序规则的话，默认为asc。

支持使用数组对多个字段的排序，例如：

Db::table('user')
->where('status', 1)
->order(['order','id'=>'desc'])
->limit(5)
->select();
最终的查询SQL可能是

SELECT \* FROM `user` WHERE `status` = 1 ORDER BY `order`,`id` desc LIMIT 5
对于更新数据或者删除数据的时候可以用于优先级限制

Db::table('user')
->where('status', 1)
->order('id', 'desc')
->limit(5)
->delete();
生成的SQL

DELETE FROM `user` WHERE `status` = 1 ORDER BY `id` desc LIMIT 5
如果你需要在order方法中使用mysql函数的话，必须使用下面的方式：

Db::table('user')
->where('status', 1)
->orderRaw("field(name,'thinkphp','onethink','kancloud')")
->limit(5)
->select();
Group
GROUP方法通常用于结合合计函数，根据一个或多个列对结果集进行分组 。

group方法只有一个参数，并且只能使用字符串。

例如，我们都查询结果按照用户id进行分组统计：

Db::table('user')
->field('user_id,username,max(score)')
->group('user_id')
->select();
生成的SQL语句是：

SELECT user_id,username,max(score) FROM score GROUP BY user_id
也支持对多个字段进行分组，例如：

Db::table('user')
->field('user_id,test_time,username,max(score)')
->group('user_id,test_time')
->select();
生成的SQL语句是：

SELECT user_id,test_time,username,max(score) FROM user GROUP BY user_id,test_time
Having
HAVING方法用于配合group方法完成从分组的结果中筛选（通常是聚合条件）数据。

having方法只有一个参数，并且只能使用字符串，例如：

Db::table('score')
->field('username,max(score)')
->group('user_id')
->having('count(test_time)>3')
->select();
生成的SQL语句是：

SELECT username,max(score) FROM score GROUP BY user_id HAVING count(test_time)>3
复制
Join
JOIN方法用于根据两个或多个表中的列之间的关系，从这些表中查询数据。通常有下面几种类型，不同类型的join操作会影响返回的数据结果。推荐使用view查询方法替代join方法。

INNER JOIN: 等同于 JOIN（默认的JOIN类型）,如果表中有至少一个匹配，则返回行
LEFT JOIN: 即使右表中没有匹配，也从左表返回所有的行
RIGHT JOIN: 即使左表中没有匹配，也从右表返回所有的行
FULL JOIN: 只要其中一个表中存在匹配，就返回行
说明
join ( mixed join [, mixed $condition = null [, string $type = 'INNER']] )
leftJoin ( mixed join [, mixed $condition = null ] )
rightJoin ( mixed join [, mixed $condition = null ] )
fullJoin ( mixed join [, mixed $condition = null ] )

参数

join
要关联的（完整）表名以及别名
支持的写法：

写法1：[ '完整表名或者子查询'=>'别名' ]
写法2：'不带数据表前缀的表名'（自动作为别名）
写法2：'不带数据表前缀的表名 别名'
condition
关联条件，只能是字符串。

type
关联类型。可以为:INNER、LEFT、RIGHT、FULL，不区分大小写，默认为INNER。

返回值
模型对象

举例
Db::table('think_artist')
->alias('a')
->join('work w','a.id = w.artist_id')
->join('card c','a.card_id = c.id')
->select();
Db::table('think_user')
->alias('a')
->join(['think_work'=>'w'],'a.id=w.artist_id')
->join(['think_card'=>'c'],'a.card_id=c.id')
->select();
默认采用INNER JOIN 方式，如果需要用其他的JOIN方式，可以改成

Db::table('think_user')
->alias('a')
->leftJoin('word w','a.id = w.artist_id')
->select();
表名也可以是一个子查询

$subsql = Db::table('think_work')
->where('status',1)
->field('artist_id,count(id) count')
->group('artist_id')
->buildSql();

Db::table('think_user')
->alias('a')
->join([$subsql=> 'w'], 'a.artist_id = w.artist_id')
->select();
Union
UNION操作用于合并两个或多个 SELECT 语句的结果集。

使用示例：

Db::field('name')
->table('think_user_0')
->union('SELECT name FROM think_user_1')
->union('SELECT name FROM think_user_2')
->select();
闭包用法：

Db::field('name')
->table('think_user_0')
->union(function ($query) {
        $query->field('name')->table('think_user_1');
    })
    ->union(function ($query) {
$query->field('name')->table('think_user_2');
})
->select();
或者

Db::field('name')
->table('think_user_0')
->union([
'SELECT name FROM think_user_1',
'SELECT name FROM think_user_2',
])
->select();
支持UNION ALL 操作，例如：

Db::field('name')
->table('think_user_0')
->unionAll('SELECT name FROM think_user_1')
->unionAll('SELECT name FROM think_user_2')
->select();
或者

Db::field('name')
->table('think_user_0')
->union(['SELECT name FROM think_user_1', 'SELECT name FROM think_user_2'], true)
->select();
每个union方法相当于一个独立的SELECT语句。

UNION 内部的 SELECT 语句必须拥有相同数量的列。列也必须拥有相似的数据类型。同时，每条 SELECT 语句中的列的顺序必须相同。
Distinct
DISTINCT 方法用于返回唯一不同的值 。

例如数据库表中有以下数据

以下代码会返回user_login字段不同的数据

Db::table('think_user')->distinct(true)->field('user_login')->select();
生成的SQL语句是：

SELECT DISTINCT user_login FROM think_user
返回以下数组

array(2) {
[0] => array(1) {
["user_login"] => string(7) "chunice"
}
[1] => array(1) {
["user_login"] => string(5) "admin"
}
}
distinct方法的参数是一个布尔值。
Lock
Lock方法是用于数据库的锁机制，如果在查询或者执行操作的时候使用：

Db::name('user')->where('id',1)->lock(true)->find();
就会自动在生成的SQL语句最后加上 FOR UPDATE或者FOR UPDATE NOWAIT（Oracle数据库）。

lock方法支持传入字符串用于一些特殊的锁定要求，例如：

Db::name('user')
->where('id',1)
->lock('lock in share mode')
->find();
Cache
cache方法用于查询缓存操作，也是连贯操作方法之一。

cache可以用于select、find、value和column方法，以及其衍生方法，使用cache方法后，在缓存有效期之内不会再次进行数据库查询操作，而是直接获取缓存中的数据，关于数据缓存的类型和设置可以参考缓存部分。

下面举例说明，例如，我们对find方法使用cache方法如下：

Db::table('user')->where('id',5)->cache(true)->find();
第一次查询结果会被缓存，第二次查询相同的数据的时候就会直接返回缓存中的内容，而不需要再次进行数据库查询操作。

默认情况下， 缓存有效期是由默认的缓存配置参数决定的，但cache方法可以单独指定，例如：

Db::table('user')->cache(true,60)->find();
// 或者使用下面的方式 是等效的
Db::table('user')->cache(60)->find();
表示对查询结果的缓存有效期60秒。

cache方法可以指定缓存标识：

Db::table('user')->cache('key',60)->find();
指定查询缓存的标识可以使得查询缓存更有效率。

这样，在外部就可以通过\think\Cache类直接获取查询缓存的数据，例如：

$result = Db::table('user')->cache('key',60)->find();
$data = \think\facade\Cache::get('key');
cache方法支持设置缓存标签，例如：

Db::table('user')->cache('key',60,'tagName')->find();
Comment
COMMENT方法 用于在生成的SQL语句中添加注释内容，例如：

Db::table('think_score')->comment('查询考试前十名分数')
->field('username,score')
->limit(10)
->order('score desc')
->select();
最终生成的SQL语句是：

SELECT username,score FROM think*score ORDER BY score desc LIMIT 10 /* 查询考试前十名分数 \_/
FetchSql
fetchSql用于直接返回SQL而不是执行查询，适用于任何的CURD操作方法。 例如：

echo Db::table('user')->fetchSql(true)->find(1);
输出结果为：

SELECT \* FROM user where `id` = 1
复制
对于某些NoSQL数据库可能不支持fetchSql方法
Force
force 方法用于数据集的强制索引操作，例如：

Db::table('user')->force('user')->select();
对查询强制使用user索引，user必须是数据表实际创建的索引名称。
Partition
partition 方法用于MySQL数据库的分区查询，用法如下：

// 用于查询
Db::name('log')
->partition(['p1','p2'])
->select();

// 用于写入
Db::name('user')
->partition('p1')
->insert(['name' => 'think', 'score' => 100']);
Replace
replace方法用于设置MySQL数据库insert方法或者insertAll方法写入数据的时候是否适用REPLACE方式。

Db::name('user')
->replace()
->insert($data);
FailException
failException设置查询数据为空时是否需要抛出异常，用于select和find方法，例如：

// 数据不存在的话直接抛出异常
Db::name('blog')
->where('status',1)
->failException()
->select();

// 数据不存在返回空数组 不抛异常
Db::name('blog')
->where('status',1)
->failException(false)
->select();
或者可以使用更方便的查空报错

// 查询多条
Db::name('blog')
->where('status', 1)
->selectOrFail();

// 查询单条
Db::name('blog')
->where('status', 1)
->findOrFail();
Extra
extra方法可以用于CURD查询，例如：

Db::name('user')
->extra('IGNORE')
->insert(['name' => 'think']);

Db::name('user')
->extra('DELAYED')
->insert(['name' => 'think']);

Db::name('user')
->extra('SQL_BUFFER_RESULT')
->select();
复制
Duplicate
用于设置DUPLICATE查询，用法示例：

Db::name('user')
->duplicate(['score' => 10])
->insert(['name' => 'think']);
Sequence
sequence方法用于pgsql数据库指定自增序列名，其它数据库不必使用，用法为：

Db::name('user')
->sequence('user_id_seq')
->insert(['name'=>'thinkphp']);
Procedure
procedure方法用于设置当前查询是否为存储过程查询，用法如下：

$resultSet = Db::procedure(true)
->query('call procedure_name');
View
view方法可以实现不依赖数据库视图的多表查询，并不需要数据库支持视图，是JOIN方法的推荐替代方法，例如：

Db::view('User', 'id,name')
->view('Profile', 'truename,phone,email', 'Profile.user_id=User.id')
->view('Score', 'score', 'Score.user_id=Profile.id')
->where('score', '>', 80)
->select();
生成的SQL语句类似于：

SELECT User.id,User.name,Profile.truename,Profile.phone,Profile.email,Score.score FROM think_user User INNER JOIN think_profile Profile ON Profile.user_id=User.id INNER JOIN think_socre Score ON Score.user_id=Profile.id WHERE Score.score > 80

﻿

注意，视图查询无需调用table和join方法，并且在调用where和order方法的时候只需要使用字段名而不需要加表名。

默认使用INNER join查询，如果需要更改，可以使用：

Db::view('User', 'id,name')
->view('Profile', 'truename,phone,email', 'Profile.user_id=User.id', 'LEFT')
->view('Score', 'score', 'Score.user_id=Profile.id', 'RIGHT')
->where('score', '>', 80)
->select();
生成的SQL语句类似于：

SELECT User.id,User.name,Profile.truename,Profile.phone,Profile.email,Score.score FROM think_user User LEFT JOIN think_profile Profile ON Profile.user_id=User.id RIGHT JOIN think_socre Score ON Score.user_id=Profile.id WHERE Score.score > 80

﻿
可以使用别名：

Db::view('User', ['id' => 'uid', 'name' => 'account'])
->view('Profile', 'truename,phone,email', 'Profile.user_id=User.id')
->view('Score', 'score', 'Score.user_id=Profile.id')
->where('score', '>', 80)
->select();

﻿
生成的SQL语句变成：

SELECT User.id AS uid,User.name AS account,Profile.truename,Profile.phone,Profile.email,Score.score FROM think_user User INNER JOIN think_profile Profile ON Profile.user_id=User.id INNER JOIN think_socre Score ON Score.user_id=Profile.id WHERE Score.score > 80

﻿
可以使用数组的方式定义表名以及别名，例如：

Db::view(['think_user' => 'member'], ['id' => 'uid', 'name' => 'account'])
->view('Profile', 'truename,phone,email', 'Profile.user_id=member.id')
->view('Score', 'score', 'Score.user_id=Profile.id')
->where('score', '>', 80)
->select();

﻿
生成的SQL语句变成：

SELECT member.id AS uid,member.name AS account,Profile.truename,Profile.phone,Profile.email,Score.score FROM think_user member INNER JOIN think_profile Profile ON Profile.user_id=member.id INNER JOIN think_socre Score ON Score.user_id=Profile.id WHERE Score.score > 80
聚合查询
在应用中我们经常会用到一些统计数据，例如当前所有（或者满足某些条件）的用户数、所有用户的最大积分、用户的平均成绩等等，ThinkORM为这些统计操作提供了一系列的内置方法，包括：

方法 说明
count 统计数量，参数是要统计的字段名（可选）
max 获取最大值，参数是要统计的字段名（必须）
min 获取最小值，参数是要统计的字段名（必须）
avg 获取平均值，参数是要统计的字段名（必须）
sum 获取总分，参数是要统计的字段名（必须）
聚合方法如果没有数据，默认都是0，聚合查询都可以配合其它查询条件

用法示例
获取用户数：

Db::table('think_user')->count();
实际生成的SQL语句是：

SELECT COUNT(\*) AS think_count FROM `think_user` LIMIT 1
或者根据字段统计：

Db::table('think_user')->count('id');
生成的SQL语句是：

SELECT COUNT(id) AS think_count FROM `think_user` LIMIT 1
获取用户的最大积分：

Db::table('think_user')->max('score');
生成的SQL语句是：

SELECT MAX(score) AS think_max FROM `think_user` LIMIT 1
如果你要获取的最大值不是一个数值，可以使用第二个参数关闭强制转换

Db::table('think_user')->max('name',false);
获取积分大于0的用户的最小积分：

Db::table('think_user')->where('score', '>', 0)->min('score');
和max方法一样，min也支持第二个参数用法

Db::table('think_user')->where('score', '>', 0)->min('name',false);
获取用户的平均积分：

Db::table('think_user')->avg('score');
生成的SQL语句是：

SELECT AVG(score) AS think_avg FROM `think_user` LIMIT 1
统计用户的总成绩：

Db::table('think_user')->where('id',10)->sum('score');
生成的SQL语句是：

SELECT SUM(score) AS think_sum FROM `think_user` LIMIT 1
如果你要使用group进行聚合查询，需要自己实现查询，例如：

Db::table('score')->field('user_id,SUM(score) AS sum_score')->group('user_id')->select();
复制
分页查询
分页实现
ThinkORM内置了分页实现，要给数据添加分页输出功能变得非常简单，可以直接在Db类查询的时候调用paginate方法：

// 查询状态为1的用户数据 并且每页显示10条数据
$list = Db::name('user')
->where('status',1)
->order('id', 'desc')
->paginate(10);

// 渲染模板输出
return view('index', ['list' => $list]);
模板文件中分页输出代码如下：

<div>
<ul>
{volist name='list' id='user'}
    <li> {$user.nickname}</li>
{/volist}
</ul>
</div>
{$list|raw}
也可以单独赋值分页输出的模板变量

// 查询状态为1的用户数据 并且每页显示10条数据
$list = Db::name('user')->where('status',1)->order('id', 'desc')->paginate(10);

// 获取分页显示
$page = $list->render();

return view('index', ['list' => $list, 'page' => $page]);
模板文件中分页输出代码如下：

<div>
<ul>
{volist name='list' id='user'}
    <li> {$user.nickname}</li>
{/volist}
</ul>
</div>
{$page|raw}
默认情况下，生成的分页输出是完整分页功能，带总分页数据和上下页码，分页样式只需要通过样式修改即可，完整分页默认生成的分页输出代码为：

<ul class="pagination">
<li><a href="?page=1">&laquo;</a></li>
<li><a href="?page=1">1</a></li>
<li class="active"><span>2</span></li>
<li class="disabled"><span>&raquo;</span></li>
</ul>
如果你需要单独获取总的数据，可以使用

// 查询状态为1的用户数据 并且每页显示10条数据
$list = Db::name('user')->where('status',1)->order('id' ,'desc')->paginate(10);
// 获取总记录数
$count = $list->total();
return view('index', ['list' => $list, 'count' => $count]);
传入总记录数
支持传入总记录数而不会自动进行总数计算，例如：

// 查询状态为1的用户数据 并且每页显示10条数据 总记录数为1000
$list = Db::name('user')->where('status',1)->paginate(10,1000);
// 获取分页显示
$page = $list->render();

return view('index', ['list' => $list, 'page' => $page]);
对于UNION查询以及一些特殊的复杂查询，推荐使用这种方式首先单独查询总记录数，然后再传入分页方法

分页后数据处理
支持分页类后数据直接each遍历处理，方便修改分页后的数据，而不是只能通过模型的获取器来补充字段。

$list = Db::name('user')
    ->where('status',1)
    ->order('id', 'desc')
    ->paginate()
    ->each(function($item, $key){
$item['nickname'] = 'think';
return $item;
});
如果是模型类操作分页数据的话，each方法的闭包函数中不需要使用返回值，例如：

$list = User::where('status',1)
    ->order('id', 'desc')
    ->paginate()
    ->each(function($item, $key){
$item->nickname = 'think';
});
简洁分页
如果你仅仅需要输出一个 仅仅只有上下页的分页输出，可以使用下面的简洁分页代码：

// 查询状态为1的用户数据 并且每页显示10条数据
$list = Db::name('user')->where('status',1)->order('id', 'desc')->paginate(10, true);

// 渲染模板输出
return view('index', ['list' => $list]);
简洁分页模式的输出代码为：

<ul class="pager">
<li><a href="?page=1">&laquo;</a></li>
<li class="disabled"><span>&raquo;</span></li>
</ul>
由于简洁分页模式不需要查询总数据数，因此可以提高查询性能。

分页参数
主要的分页参数如下：

参数 描述
list_rows 每页数量
page 当前页
path url路径
query url额外参数
fragment url锚点
var_page 分页变量
分页参数的设置可以在调用分页方法的时候传入，例如：

$list = Db::name('user')->where('status',1)->paginate([
'list_rows'=> 20,
'var_page' => 'page',
]);
如果需要在分页的时候传入查询条件，可以使用query参数拼接额外的查询参数

大数据分页
对于大量数据的分页查询，系统提供了一个高性能的paginateX分页查询方法，用法和paginate分页查询存在一定区别。如果你要分页查询的数据量在百万级以上，使用paginateX方法会有明显的提升，尤其是在分页数较大的情况下。并且由于针对大数据量而设计，该分页查询只能采用简洁分页模式，所以没有总数。

分页查询的排序字段一定要使用索引字段，并且是连续的整型，否则会有数据遗漏。

主要场景是针对主键进行分页查询，默认使用主键倒序查询分页数据。

$list = Db::name('user')->where('status',1)->paginateX(20);
也可以在查询的时候可以指定主键和排序

$list = Db::name('user')->where('status',1)->paginateX(20, 'id', 'desc');
查询方法会执行两次查询，第一次查询用于查找满足当前查询条件的最大或者最小值，然后配合主键查询条件来进行分页数据查询。

查询更多数据
more方法用于查询更多的数据，比如手机下翻显示更多数据的场景。该方法需要传入LastId，支持指定排序键（默认为主键），下面的查询表示从主键100开始查询下20条用户数据

$result = Db::name('user')->more(20, 100);
$data = $result['data'];
$lastId = $result['lastId'];
默认以主键倒序查询，支持指定排序字段和排序。

$list = Db::name('user')->more(20, 10, 'create_time', 'desc');
自定义分页类
在ThinkPHP6.0+，如果你需要自定义分页，可以扩展一个分页驱动。

然后在provider.php定义文件中重新绑定

return [
'think\Paginator' => 'app\common\Bootstrap'
];
时间查询
时间比较
内置了常用的时间查询方法，并且可以自动识别时间字段的类型，所以无论采用什么类型的时间字段，都可以统一使用本章的时间查询用法。

使用whereTime方法
whereTime方法提供了日期和时间字段的快捷查询，示例如下：

// 大于某个时间
Db::name('user')
->whereTime('birthday', '>=', '1970-10-1')
->select();
// 小于某个时间
Db::name('user')
->whereTime('birthday', '<', '2000-10-1')
->select();
// 时间区间查询
Db::name('user')
->whereTime('birthday', 'between', ['1970-10-1', '2000-10-1'])
->select();
// 不在某个时间区间
Db::name('user')
->whereTime('birthday', 'not between', ['1970-10-1', '2000-10-1'])
->select();
还可以使用下面的时间表达式进行时间查询

// 查询两个小时内的博客
Db::name('blog')
->whereTime('create_time','-2 hours')
->select();
查询某个时间区间
针对时间的区间查询，系统还提供了whereBetweenTime/whereNotBetweenTime快捷方法。

// 查询2017年上半年注册的用户
Db::name('user')
->whereBetweenTime('create_time', '2017-01-01', '2017-06-30')
->select();

// 查询不是2017年上半年注册的用户
Db::name('user')
->whereNotBetweenTime('create_time', '2017-01-01', '2017-06-30')
->select();
查询某年
查询今年注册的用户

Db::name('user')
->whereYear('create_time')
->select();  
查询去年注册的用户

Db::name('user')
->whereYear('create_time', 'last year')
->select();  
查询某一年的数据使用

// 查询2018年注册的用户
Db::name('user')
->whereYear('create_time', '2018')
->select();  
查询某月
查询本月注册的用户

Db::name('user')
->whereMonth('create_time')
->select();  
查询上月注册用户

Db::name('user')
->whereMonth('create_time','last month')
->select();  
查询2018年6月注册的用户

Db::name('user')
->whereMonth('create_time', '2018-06')
->select();  
查询某周
查询本周数据

Db::name('user')
->whereWeek('create_time')
->select();  
查询上周数据

Db::name('user')
->whereWeek('create_time', 'last week')
->select();  
查询指定某天开始的一周数据

// 查询2019-1-1到2019-1-7的注册用户
Db::name('user')
->whereWeek('create_time', '2019-1-1')
->select();  
查询某天
查询当天注册的用户

Db::name('user')
->whereDay('create_time')
->select();  
查询昨天注册的用户

Db::name('user')
->whereDay('create_time', 'yesterday')
->select();  
查询某天的数据使用

// 查询2018年6月1日注册的用户
Db::name('user')
->whereDay('create_time', '2018-06-01')
->select();  
时间字段区间比较
可以支持对两个时间字段的区间比较

// 查询有效期内的活动
Db::name('event')
->whereBetweenTimeField('start_time', 'end_time')
->select();
上面的查询相当于

// 查询有效期内的活动
Db::name('event')
->whereTime('start_time', '<=', time())
->whereTime('end_time', '>=', time())
->select();
自定义时间查询规则
你可以通过在数据库配置文件中设置time_query_rule添加自定义的时间查询规则，

'time_query_rule' => [
'hour' => ['1 hour ago', 'now'],
],
高级查询
快捷查询
快捷查询方式是一种多字段相同查询条件的简化写法，可以进一步简化查询条件的写法，在多个字段之间用|分割表示OR查询，用&分割表示AND查询，可以实现下面的查询，例如：

Db::table('think_user')
->where('name|title','like','thinkphp%')
->where('create_time&update_time','>',0)
->find();
生成的查询SQL是：

SELECT \* FROM `think_user` WHERE ( `name` LIKE 'thinkphp%' OR `title` LIKE 'thinkphp%' ) AND ( `create_time` > 0 AND `update_time` > 0 ) LIMIT 1
快捷查询支持所有的查询表达式。

枚举查询
如果你的数据字段使用了枚举类型并且定义了枚举类StatusEnum，可以使用

Db::table('think_user')
->where('status',StatusEnum::Normal)
->find();
会自动转换为value值进行写入。

数组查询
可以进行多个条件的批量条件查询定义，例如：

Db::table('think_user')
->where([
['name', 'like', 'thinkphp%'],
['title', 'like', '%thinkphp'],
['id', '>', 0],
['status', '=', 1],
])
->select();
生成的SQL语句为：

SELECT \* FROM `think_user` WHERE `name` LIKE 'thinkphp%' AND `title` LIKE '%thinkphp' AND `id` > 0 AND `status` = '1'
数组方式如果使用exp查询的话，一定要用raw方法。

Db::table('think_user')
->where([
['name', 'like', 'thinkphp%'],
['title', 'like', '%thinkphp'],
['id', 'exp', Db::raw('>score')],
['status', '=', 1],
])
->select();
数组查询方式，确保你的查询数组不能被用户提交数据控制，用户提交的表单数据应该是作为查询数组的一个元素传入，如下：

Db::table('think_user')
->where([
['name', 'like', $name . '%'],
['title', 'like', '%' . $title],
['id', '>', $id],
['status', '=', $status],
])
->select();
注意，相同的字段的多次查询条件可能会合并，如果希望某一个where方法里面的条件单独处理，可以使用下面的方式，避免被其它条件影响。

$map = [
['name', 'like', 'thinkphp%'],
['title', 'like', '%thinkphp'],
['id', '>', 0],
];
Db::table('think_user')
->where([ $map ])
->where('status',1)
->select();
生成的SQL语句为：

SELECT \* FROM `think_user` WHERE ( `name` LIKE 'thinkphp%' AND `title` LIKE '%thinkphp' AND `id` > 0 ) AND `status` = '1'
如果使用下面的多个条件组合

$map1 = [
['name', 'like', 'thinkphp%'],
['title', 'like', '%thinkphp'],
];

$map2 = [
['name', 'like', 'kancloud%'],
['title', 'like', '%kancloud'],
];

Db::table('think_user')
->whereOr([ $map1, $map2 ])
->select();
生成的SQL语句为：

SELECT \* FROM `think_user` WHERE ( `name` LIKE 'thinkphp%' AND `title` LIKE '%thinkphp' ) OR ( `name` LIKE 'kancloud%' AND `title` LIKE '%kancloud' )
善用多维数组查询，可以很方便的拼装出各种复杂的SQL语句

闭包查询
$name = 'thinkphp';
$id = 10;
Db::table('think_user')->where(function ($query) use($name, $id) {
$query->where('name', $name)
->whereOr('id', '>', $id);
})->select();
生成的SQL语句为：

SELECT \* FROM `think_user` WHERE ( `name` = 'thinkphp' OR `id` > 10 )
每个闭包条件两边也会自动加上括号。

字符串条件查询
也可以直接使用原生SQL语句进行查询，例如：

Db::table('think_user')
->whereRaw('id > 0 AND name LIKE "thinkphp%"')
->select();
为了安全起见，我们可以对字符串查询条件使用参数绑定，例如：

Db::table('think_user')
->whereRaw('id > :id AND name LIKE :name ', ['id' => 0, 'name' => 'thinkphp%'])
->select();
快捷方法
系统封装了一系列快捷方法，用于简化查询，包括：

方法 作用
whereOr 字段OR查询
whereXor 字段XOR查询
whereNull 查询字段是否为Null
whereNotNull 查询字段是否不为Null
whereIn 字段IN查询
whereNotIn 字段NOT IN查询
whereBetween 字段BETWEEN查询
whereNotBetween 字段NOT BETWEEN查询
whereLike 字段LIKE查询
whereNotLike 字段NOT LIKE查询
whereExists EXISTS条件查询
whereNotExists NOT EXISTS条件查询
whereExp 表达式查询
whereColumn 比较两个字段
下面举例说明下两个字段比较的查询条件whereColumn方法的用法。

查询update_time大于create_time的用户数据

Db::table('think_user')
->whereColumn('update_time','>','create_time')
->select();
生成的SQL语句是：

SELECT \* FROM `think_user` WHERE ( `update_time` > `create_time` )
查询name和nickname相同的用户数据

Db::table('think_user')
->whereColumn('name','=','nickname')
->select();
生成的SQL语句是：

SELECT \* FROM `think_user` WHERE ( `name` = `nickname` )
相同字段条件也可以简化为

Db::table('think_user')
->whereColumn('name','nickname')
->select();
支持数组方式比较多个字段

Db::name('user')->whereColumn([
['title', '=', 'name'],
['update_time', '>=', 'create_time'],
])->select();
生成的SQL语句是：

SELECT \* FROM `think_user` WHERE ( `name` = `nickname` AND `update_time` > `create_time` )
动态查询
查询构造器还提供了动态查询机制，用于简化查询条件，包括：

动态查询 描述
whereFieldName 查询某个字段的值
whereOrFieldName 查询某个字段的值
getByFieldName 根据某个字段查询
getFieldByFieldName 根据某个字段获取某个值
其中FieldName表示数据表的实际字段名称的驼峰法表示，假设数据表user中有email和nick_name字段，我们可以这样来查询。

// 根据邮箱（email）查询用户信息
$user = Db::table('user')
->whereEmail('thinkphp@qq.com')
->find();

// 根据昵称（nick_name）查询用户
$email = Db::table('user')
->whereNickName('like', '%流年%')
->select();

// 根据邮箱查询用户信息
$user = Db::table('user')
->getByEmail('thinkphp@qq.com');

// 根据昵称（nick_name）查询用户信息
$user = Db::table('user')
->field('id,name,nick_name,email')
->getByNickName('流年');

// 根据邮箱查询用户的昵称
$nickname = Db::table('user')
->getFieldByEmail('thinkphp@qq.com', 'nick_name');

// 根据昵称（nick_name）查询用户邮箱
$email = Db::table('user')
->getFieldByNickName('流年', 'email');
getBy和getFieldBy方法只会查询一条记录，可以和其它的链式方法搭配使用

条件查询
查询构造器支持条件查询，例如：

Db::name('user')->when($condition, function ($query) {
// 满足条件后执行
$query->where('score', '>', 80)->limit(10);
})->select();
并且支持不满足条件的分支查询

Db::name('user')->when($condition, function ($query) {
// 满足条件后执行
$query->where('score', '>', 80)->limit(10);
}, function ($query) {
// 不满足条件执行
$query->where('score', '>', 60);
});
复制
子查询
首先构造子查询SQL，可以使用下面三种的方式来构建子查询。

使用fetchSql方法

﻿
fetchSql方法表示不进行查询而只是返回构建的SQL语句，支持所有的CURD查询。

$subQuery = Db::table('think_user')
->field('id,name')
->where('id', '>', 10)
->fetchSql(true)
->select();
﻿生成的subQuery结果为：

SELECT `id`,`name` FROM `think_user` WHERE `id` > 10

﻿

使用buildSql构造子查询
$subQuery = Db::table('think_user')
->field('id,name')
->where('id', '>', 10)
->buildSql();

﻿
生成的subQuery结果为：

( SELECT `id`,`name` FROM `think_user` WHERE `id` > 10 )

﻿
调用buildSql方法后不会进行实际的查询操作，而只是生成该次查询的SQL语句（为了避免混淆，会在SQL两边加上括号），然后我们直接在后续的查询中直接调用。

然后使用子查询构造新的查询：

Db::table($subQuery . ' a')
->where('a.name', 'like', 'thinkphp')
->order('id', 'desc')
->select();

﻿
生成的SQL语句为：

SELECT \* FROM ( SELECT `id`,`name` FROM `think_user` WHERE `id` > 10 ) a WHERE a.name LIKE 'thinkphp' ORDER BY `id` desc

﻿

使用闭包构造子查询

﻿
IN/NOT IN和EXISTS/NOT EXISTS之类的查询可以直接使用闭包作为子查询，例如：

Db::table('think_user')
->where('id', 'IN', function ($query) {
$query->table('think_profile')->where('status', 1)->field('id');
})
->select();

﻿
生成的SQL语句是

SELECT \* FROM `think_user` WHERE `id` IN ( SELECT `id` FROM `think_profile` WHERE `status` = 1 )

﻿

Db::table('think_user')
->whereExists(function ($query) {
$query->table('think_profile')->where('status', 1);
})->find();
生成的SQL语句为

SELECT _ FROM `think_user` WHERE EXISTS ( SELECT _ FROM `think_profile` WHERE `status` = 1 )

﻿

除了上述查询条件外，比较运算也支持使用闭包子查询
原生查询
Db支持原生SQL查询操作，主要包括下面两个方法：

原生查询仅支持Db类操作，不支持在模型中调用原生查询方法（包括query和execute方法）。

query方法

﻿
query方法用于执行SQL查询操作，和select方法一样返回查询结果数据集（数组）。

使用示例：

Db::query('select \* from think_user where status = 1');
如果你当前采用了分布式数据库，并且设置了读写分离的话，query方法默认是在读服务器执行，而不管你的SQL语句是什么。

如果希望从主库读取，可以使用

Db::master(true)->query('select \* from think_user where status = 1');

﻿

execute方法

﻿
execute用于更新和写入数据的sql操作，如果数据非法或者查询错误则返回false ，否则返回影响的记录数。

使用示例：

Db::execute("update think_user set name='thinkphp' where status=1");

﻿

如果你当前采用了分布式数据库，并且设置了读写分离的话，execute方法始终是在写服务器执行，而不管你的SQL语句是什么。

参数绑定

﻿
支持在原生查询的时候使用参数绑定，包括问号占位符或者命名占位符，例如：

Db::query("select \* from think_user where id=? AND status=?", [8, 1]);
// 命名绑定
Db::execute("update think_user set name=:name where status=:status", ['name' => 'thinkphp', 'status' => 1]);

﻿

注意不支持对表名使用参数绑定
事务操作
使用事务处理的话，需要数据库引擎支持事务处理。比如 MySQL 的 MyISAM 不支持事务处理，需要使用 InnoDB 引擎。

最简单的方式是使用 transaction 方法操作数据库事务，当闭包中的代码发生异常会自动回滚，例如：

Db::transaction(function () {
Db::table('think_user')->find(1);
Db::table('think_user')->delete(1);
});
也可以手动控制事务，例如：

// 启动事务
Db::startTrans();
try {
Db::table('think_user')->find(1);
Db::table('think_user')->delete(1);
// 提交事务
Db::commit();
} catch (\Exception $e) {
// 回滚事务
Db::rollback();
}
注意在事务操作的时候，确保你的数据库连接使用的是同一个。

可以支持MySQL的XA事务用于实现全局（分布式）事务，你可以使用：

Db::transactionXa(function () {
Db::connect('db1')->table('think_user')->delete(1);
Db::connect('db2')->table('think_user')->delete(1);
}, [Db::connect('db1'),Db::connect('db2')]);
要确保你的数据表引擎为InnoDB，并且开启XA事务支持。
存储过程
数据访问层支持存储过程调用，调用数据库存储过程使用下面的方法：

$resultSet = Db::query('call procedure_name');
foreach ($resultSet as $result) {

}
存储过程返回的是一个数据集，如果你的存储过程不需要返回任何的数据，那么也可以使用execute方法：

Db::execute('call procedure_name');
存储过程可以支持输入和输出参数，以及进行参数绑定操作。

$resultSet = Db::query('call procedure_name(:in_param1,:in_param2,:out_param)', [
    'in_param1' => $param1,
    'in_param2' => [$param2, PDO::PARAM_INT],
'out_param' => [$outParam, PDO::PARAM_STR | PDO::PARAM_INPUT_OUTPUT, 4000],
]);
输出参数的绑定必须额外使用PDO::PARAM_INPUT_OUTPUT，并且可以和输入参数公用一个参数。

无论存储过程内部做了什么操作，每次存储过程调用仅仅被当成一次查询。
查询事件
查询事件
数据库操作的回调也称为查询事件，是针对数据库的CURD操作而设计的回调方法，主要包括：

事件 描述
before_select select查询前回调
before_find find查询前回调
after_insert insert操作成功后回调
after_update update操作成功后回调
after_delete delete操作成功后回调
使用下面的方法注册数据库查询事件

Db::event('before_select', function ($query) {
// 事件处理
});
同一个查询事件可以注册多个响应执行。

如果是在ThinkPHP6.0+中使用的话，查询事件已经被事件系统接管了，但用法是一致的。

查询事件的方法参数只有一个：当前的查询对象。但你可以通过依赖注入的方式添加额外的参数。
JSON字段
如果你的user表有一个info字段是JSON类型的（或者说你存储的是JSON格式，但并非是要JSON字段类型），你可以使用下面的方式操作数据。

JSON数据写入
$user['name'] = 'thinkphp';
$user['info'] = [
'email' => 'thinkphp@qq.com',
'nickname' => '流年',
];
Db::name('user')
->json(['info'])
->insert($user);
JSON数据查询
查询整个JSON数据：

$user = Db::name('user')
	->json(['info'])
	->find(1);
dump($user);
查询条件为JSON数据

$user = Db::name('user')
	->json(['info'])
    ->where('info->nickname','ThinkPHP')
	->find();
dump($user);
或者使用whereJsonContains方法

$user = Db::name('user')
->whereJsonContains('info', 'thinkphp')
->whereOrJsonContains('info->name', 'thinkphp')
->find();
由于JSON字段的属性类型并不会自动获取，所以，如果是整型数据查询的话，可以设置JSON字段类型，例如：

$user = Db::name('user')
	->json(['info'])
    ->where('info->user_id', 10)
	->setFieldType(['info->user_id' => 'int'])
	->find();
dump($user);
聚合查询
可以直接使用下面的方式进行json字段数据的聚合查询

$result = Db::name('user')
    ->json(['info'])
    ->where('info->user_id', 10)
    ->field('id,SUM(info->"$.score")')
->find();
$count = Db::name('user')
->json(['info'])
->where('info->score', '>', 80)
->count('info->user_id');
JSON数据更新
完整JSON数据更新

$data['info'] = [
	'email'    => 'kancloud@qq.com',
	'nickname' => 'kancloud',
];
Db::name('user')
	->json(['info'])
    ->where('id',1)
	->update($data);
单个JSON数据更新

$data['info->nickname'] = 'ThinkPHP';
Db::name('user')
	->json(['info'])
    ->where('id',1)
	->update($data);
复制
模型
模型是ThinkORM的一个重要组成，Db和模型的存在只是ThinkORM架构设计中的职责和定位不同，Db负责的只是数据（表）访问，模型负责的是业务数据和业务逻辑，实现了数据对象化访问的封装。

相对于使用Db类来说模型的优势主要在于：

支持ActiveRecord实现；
灵活的事件机制；
数据自动处理能力；
简单直观的数据关联操作；
封装业务逻辑；
定义
模型定义
定义一个模型类很简单，下面是一个最简单的User模型：

<?php
namespace app\model;

use think\Model;

class User extends Model
{
}
请确保你已经在数据库配置文件中配置了数据库连接信息，如不清楚请参考数据库一章

模型会自动对应数据表，模型类的命名规则是除去表前缀的数据表名称，采用驼峰法命名，并且首字母大写，例如：

模型名	约定对应数据表（假设数据库的前缀定义是 think_）
User	think_user
UserType	think_user_type
如果你的规则和上面的系统约定不符合，那么需要设置模型类的数据表名称table属性，以确保能够找到对应的数据表。

模型自动对应的数据表名称都是遵循小写+下划线规范，如果你的表名有大写的情况，必须通过设置模型的table属性。

如果你希望给模型类添加后缀，必须要设置name属性或者table属性。

<?php
namespace app\model;

use think\Model;

class UserModel extends Model
{
    protected $name = 'user';
}
模型设置
默认主键为id，如果你没有使用id作为主键名，需要在模型中设置属性：

<?php
namespace app\model;

use think\Model;

class User extends Model
{
    protected $pk = 'uid';
}
如果你想指定数据表甚至数据库连接的话，可以使用：

<?php
namespace app\model;

use think\Model;

class User extends Model
{
    // 设置当前模型对应的完整数据表名称
    protected $table = 'think_user';
    
    // 设置当前模型的数据库连接
    protected $connection = 'db_config';
}
connection属性使用用配置参数名（需要在数据库配置文件中的connections参数中添加对应标识）。

常用的模型设置属性包括（以下属性都不是必须设置）：

属性	描述
name	模型名（相当于不带数据表前后缀的表名，默认为当前模型类名）
table	数据表名（默认自动获取）
suffix	数据表后缀（默认为空）
pk	主键名（默认为id）
autoInc	数据表自增主键 支持字符串或true（自动获取主键值）
connection	数据库连接（默认读取数据库配置）
field	模型允许写入的字段列表（数组）
schema	模型对应数据表字段及类型（数组）
type	模型需要自动转换的字段及类型（数组）
strict	是否严格区分字段大小写（默认为true）
disuse	数据表废弃字段（数组）
模型不支持对数据表的前缀单独设置，并且也不推荐使用数据表的前缀设计，应该用不同的库区分。当你的数据表没有前缀的时候，name和table属性的定义是没有区别的，定义任何一个即可。

字段定义
模型的数据字段和对应数据表的字段是对应的，默认会自动获取（包括字段类型），但自动获取会导致增加一次查询，因此你可以在模型中明确定义字段信息避免多一次查询的开销。

<?php
namespace app\model;

use think\Model;

class User extends Model
{
    // 设置字段信息
    protected $schema = [
        'id'          => 'int',
        'name'        => 'string',
        'status'      => 'int',
        'score'       => 'float',
        'create_time' => 'datetime',
        'update_time' => 'datetime',
    ];
}
字段类型的定义可以使用PHP类型或者数据库的字段类型都可以，字段类型定义的作用主要用于查询的参数自动绑定类型。

时间字段尽量采用实际的数据库类型定义，便于时间查询的字段自动识别。如果是json类型直接定义为json即可。

如果在ThinkPHP6.0+中使用的话，没有定义schema属性的话，可以在部署完成后运行如下指令。

php think optimize:schema
运行后会自动生成数据表的字段信息缓存。使用命令行缓存的优势是Db类的查询仍然有效。

字段类型
schema属性一旦定义，就必须定义完整的数据表字段类型。
如果你只希望对某个字段定义需要自动转换的类型，可以使用type属性，例如：

<?php
namespace app\model;

use think\Model;

class User extends Model
{
    // 设置字段自动转换类型
    protected $type = [
        'score'       => 'float',
    ];
}
type属性定义的不一定是实际的字段，也有可能是你的字段别名。

废弃字段
如果因为历史遗留问题 ，你的数据表存在很多的废弃字段，你可以在模型里面定义这些不再使用的字段。

<?php
namespace app\model;

use think\Model;

class User extends Model
{
    // 设置废弃字段
    protected $disuse = [ 'status', 'type' ];
}
在查询和写入的时候会忽略定义的status和type废弃字段。

获取数据
在模型外部获取数据的方法如下

$user = User::find(1);
echo $user->create_time;  
echo $user->name;
由于模型类实现了ArrayAccess接口，所以可以当成数组使用。

$user = User::find(1);
echo $user['create_time'];  
echo $user['name'];
如果你是在模型内部获取数据的话，需要改成：

$user = $this->find(1);
echo $user->getAttr('create_time');  
echo $user->getAttr('name');
否则可能会出现意想不到的错误。

模型赋值
可以使用下面的代码给模型对象赋值

$user = new User();
$user->name = 'thinkphp';
$user->score = 100;
该方式赋值会自动执行模型的修改器，如果不希望执行修改器操作，可以使用

$data['name'] = 'thinkphp';
$data['score'] = 100;
$user = new User($data);
或者使用

$user = new User();
$data['name'] = 'thinkphp';
$data['score'] = 100;
$user->data($data);
字段大小写
默认情况下，你的模型数据名称和数据表字段应该保持严格一致，也就是说区分大小写。

$user = User::find(1);
echo $user->create_time;  // 正确
echo $user->createTime;  // 错误
严格区分字段大小写的情况下，如果你的数据表字段是大写，模型获取的时候也必须使用大写。

如果你希望在获取模型数据的时候不区分大小写（前提是数据表的字段命名必须规范，即小写+下划线），可以设置模型的strict属性。

<?php
namespace app\model;

use think\Model;

class User extends Model 
{
    // 模型数据不区分大小写
    protected $strict = false,
}
你现在可以使用

$user = User::find(1);
// 下面两种方式都有效
echo $user->createTime; 
echo $user->create_time; 
前提是你实际的数据表字段必须符合规范，采用小写和下划线设计，例如这里必须是create_time。

模型数据转驼峰
V2.0.34+版本开始，可以设置convertNameToCamel属性使得模型数据返回驼峰方式命名（前提也是数据表的字段命名必须规范，即小写+下划线）。

<?php
namespace app\model;

use think\Model;

class User extends Model 
{
    // 数据转换为驼峰命名
    protected $convertNameToCamel = true,
}
然后在模型输出的时候可以直接使用驼峰命名的方式获取。

$user = User::find(1);
$data = $user->toArray();
echo $data['createTime']; // 正确 
echo $user['create_time'];  // 错误
模型初始化
模型支持初始化，只需要定义init方法，例如：

<?php
namespace app\model;

use think\Model;

class User extends Model
{
    // 模型初始化
    protected static function init()
    {
        //TODO:初始化内容
    }
}
init必须是静态方法，并且只在第一次实例化的时候执行，并且只会执行一次

模型操作
在模型中除了可以调用数据库类的方法之外（换句话说，数据库的所有查询构造器方法模型中都可以支持），可以定义自己的方法，所以也可以把模型看成是数据库的增强版。

模型的操作方法无需和数据库查询一样调用必须首先调用table或者name方法，因为模型会按照规则自动匹配对应的数据表，例如：

Db::name('user')->where('id','>',10)->select();
改成模型操作的话就变成

User::where('id','>',10)->select();
虽然看起来是相同的查询条件，但一个最明显的区别是查询结果的类型不同。第一种方式的查询结果是一个普通的数据集对象，而第二种方式的查询结果是包含了模型数据集对象。

模型操作和数据库操作的另外一个显著区别是模型支持包括获取器、修改器、自动时间写入在内的一系列自动化操作和事件，简化了数据的存取操作，但随之而来的是性能有所下降（其实并没下降，而是自动帮你处理了一些原本需要手动处理的操作），后面会逐步领略到模型的这些特色功能。

动态切换后缀
数据表后缀属性，可以用于多语言或者数据分表的模型查询，省去为多个相同结构的表定义多个模型的麻烦。

默认的数据表后缀可以在模型类里面直接定义suffix属性。

<?php
namespace app\model;

use think\Model;

class Blog extends Model
{
    // 定义默认的表后缀（默认查询中文数据）
    protected $suffix = _cn';
}
你在模型里面定义的name和table属性无需包含后缀定义

模型提供了动态切换方法suffix和setSuffix，例如：

// suffix方法用于静态查询
$blog = Blog::suffix('_en')->find();
$blog->name = 'test';
$blog->save();

// setSuffix用于动态设置
$blog = new Blog($data);
$blog->setSuffix('_en')->save();
模型方法依赖注入
如果你需要对模型的方法支持依赖注入，可以把模型的方法改成闭包的方式，例如，你需要对获取器方法增加依赖注入

public function getTestFieldAttr($value,$data) {
    return $this->invoke(function(Request $request)  use($value,$data) {
        return $data['name'] . $request->action();
    };
}
不仅仅是获取器方法，在任何需要依赖注入的方法都可以改造为调用invoke方法的方式，invoke方法第二个参数用于传入需要调用的（数组）参数。

如果你需要直接调用某个已经定义的模型方法（假设已经使用了依赖注入），可以使用

protected function bar($name, Request $request) {
    // ...
}

protected function invokeCall(){
    return $this->invoke('bar',['think']);
}
新增
模型数据的新增和数据库的新增数据有所区别，数据库的新增只是单纯的写入给定的数据，而模型的数据写入会包含修改器、自动完成以及模型事件等环节，数据库的数据写入参考查询构造器新增数据章节。

添加一条数据
第一种是实例化模型对象后赋值并保存：

$user           = new User;
$user->name     = 'thinkphp';
$user->email    = 'thinkphp@qq.com';
$user->save();
save方法成功会返回true，并且只有当before_insert事件返回false的时候返回false，一旦有错误就会抛出异常。所以无需判断返回类型。

也可以直接传入数据到save方法批量赋值：

$user = new User;
$user->save([
    'name'  =>  'thinkphp',
    'email' =>  'thinkphp@qq.com'
]);
默认只会写入数据表已有的字段，如果你通过外部提交赋值给模型，并且希望指定某些字段写入，可以使用：

$user = new User;
// post数组中只有name和email字段会写入
$user->allowField(['name','email'])->save($_POST);
最佳的建议是模型数据赋值之前就进行数据过滤，例如：

$user = new User;
// 过滤post数组中的非数据表字段数据
$data = Request::only(['name','email']);
$user->save($data);
save方法新增数据返回的是布尔值。

Replace写入
save方法可以支持replace写入。

$user           = new User;
$user->name     = 'thinkphp';
$user->email    = 'thinkphp@qq.com';
$user->replace()->save();
获取自增ID
如果要获取新增数据的自增ID，可以使用下面的方式：

$user           = new User;
$user->name     = 'thinkphp';
$user->email    = 'thinkphp@qq.com';
$user->save();
// 获取自增ID
echo $user->id;
这里其实是获取模型的主键，如果你的主键不是id，而是user_id的话，其实获取自增ID就变成这样：

$user           = new User;
$user->name     = 'thinkphp';
$user->email    = 'thinkphp@qq.com';
$user->save();
// 获取自增ID
echo $user->user_id;
不要在同一个实例里面多次新增数据，如果确实需要多次新增，可以使用后面的静态方法处理。

主键自动写入
如果你希望主键自动写入（不采用数据库的自增主键机制），可以在模型类中定义如下。

<?php
namespace app\model;

use think\Model;

class User extends Model
{
    protected $autoWriteId = true;
    protected function autoWriteId()
    {
        // 假设在公共函数文件中定义了uuid函数
        return uuid();
    }
}
在新增数据的时候会自动写入主键字段值

$user = User::create([
    'name'  =>  'thinkphp',
    'email' =>  'thinkphp@qq.com'
]);
echo $user->name;
echo $user->email;
echo $user->id; // 获取主键值 EA9AFB21-8F21-8507-7379-814CAC5A419B
数据自动写入
如果你需要在创建数据的时候自动写入相关字段，可以通过定义insert属性并配合修改器来完成。下面是一个自动写入订单编号的例子：

<?php
namespace app\model;

use think\Model;

class Order extends Model
{
    protected $insert = ['order_no'];
    protected $readonly = ['order_no'];
    protected function setOrderNoAttr($value, $data)
    {
        return $data['type'] . '-' . date('YmdHis') . mt_rand(1000, 9999);
    }
}
创建订单会自动写入订单编号字段order_no，自动写入的前提是必须有定义修改器方法或定义了类型转换接口实现。同时这里还设置了只读字段，更新的时候不会写入。

如果你需要自动写入一个固定的值，可以使用下面的定义

<?php
namespace app\model;

use think\Model;

class Order extends Model
{
    protected $insert = ['status' => 1];
}
在新增数据的时候会自动写入status为1的状态值。

批量增加数据
支持批量新增，可以使用：

$user = new User;
$list = [
    ['name'=>'thinkphp','email'=>'thinkphp@qq.com'],
    ['name'=>'onethink','email'=>'onethink@qq.com']
];
$user->saveAll($list);
saveAll方法新增数据返回的是包含新增模型（带自增ID）的数据集对象。

saveAll方法新增数据默认会自动识别数据是需要新增还是更新操作，当数据中存在主键的时候会认为是更新操作。

静态方法
还可以直接静态调用create方法创建并写入：

$user = User::create([
    'name'  =>  'thinkphp',
    'email' =>  'thinkphp@qq.com'
]);
echo $user->name;
echo $user->email;
echo $user->id; // 获取自增ID
和save方法不同的是，create方法返回的是当前模型的对象实例。

create方法默认会过滤不是数据表的字段信息，可以在第二个参数可以传入允许写入的字段列表，例如：

// 只允许写入name和email字段的数据
$user = User::create([
    'name'  =>  'thinkphp',
    'email' =>  'thinkphp@qq.com'
], ['name', 'email']);
echo $user->name;
echo $user->email;
echo $user->id; // 获取自增ID
支持replace操作，使用下面的方法：

$user = User::create([
    'name'  =>  'thinkphp',
    'email' =>  'thinkphp@qq.com'
], ['name','email'], true);
最佳实践
新增数据的最佳实践原则：使用create方法新增数据，使用saveAll批量新增数据。
更新
和模型新增一样，更新操作同样也会经过修改器、自动完成以及模型事件等处理，并不等同于数据库的数据更新，而且更新方法和新增方法使用的是同一个方法，通常系统会自动判断需要新增还是更新数据。

查找并更新
在取出数据后，更改字段内容后使用save方法更新数据。这种方式是最佳的更新方式。

$user = User::find(1);
$user->name     = 'thinkphp';
$user->email    = 'thinkphp@qq.com';
$user->save();
支持传入数组进行数据更新

$user = User::find(1);
$user->save([
    'name'    =>    'thinkphp',
    'email'    =>    'thinkphp@qq.com'
]);
3.0+版本支持传入模型实例或其它实体对象实例进行更新。

$profile = Profile::find(2);
$user = User::find(1);
$user->save($profile);
save方法成功返回true，并只有当before_update事件返回false的时候返回false，有错误则会抛出异常。

save方法更新数据，只会更新变化的数据，对于没有变化的数据是不会进行重新更新的。如果你需要强制更新数据，可以使用下面的方法：

$user = User::find(1);
$user->name     = 'thinkphp';
$user->email    = 'thinkphp@qq.com';
$user->force()->save();
这样无论你的修改后的数据是否和之前一样都会强制更新该字段的值。

如果要执行SQL函数更新，可以使用下面的方法

$user = User::find(1);
$user->name     = 'thinkphp';
$user->email    = 'thinkphp@qq.com';
$user->score	=  raw('score+1');
$user->save();
自增/自减
如果要更新的字段是数值类型，可以使用inc/dec方法自增或自减一个字段的值（ 如不加第二个参数，默认步长为1）。

$user = User::find(1);

// login_times加1  score减2 
$user->inc('login_times', 1)
    ->dec('score', 2)
    ->save();
如果你使用统一数据更新，可以使用助手函数inc/dec

$user = User::find(1);

$data['login_time'] = inc(1);
$data['score']      = dec(2);
$user->save($data);
字段过滤
默认情况下会过滤非数据表字段的数据，如果你通过外部提交赋值给模型，并且希望指定某些字段写入，可以使用：

$user = User::find(1);
// post数组中只有name和email字段会写入
$user->allowField(['name', 'email'])->save($_POST);
最佳实践是在传入模型数据之前就进行过滤，例如：

$user = User::find(1);
// post数组中只有name和email字段会写入
$data = Request::only(['name','email']);
$user->save($data);
批量更新数据
可以使用saveAll方法批量更新数据，只需要在批量更新的数据中包含主键即可，例如：

$user = new User;
$list = [
    ['id'=>1, 'name'=>'thinkphp', 'email'=>'thinkphp@qq.com'],
    ['id'=>2, 'name'=>'onethink', 'email'=>'onethink@qq.com']
];
$user->saveAll($list);
批量更新方法返回的是一个数据集对象。

批量更新仅能根据主键值进行更新，其它情况请自行处理。

直接更新（静态方法）
使用模型的静态update方法更新：

User::update(['name' => 'thinkphp'], ['id' => 1]);
模型的update方法返回模型的对象实例

如果你的第一个参数中包含主键数据，可以无需传入第二个参数（更新条件）

User::update(['name' => 'thinkphp', 'id' => 1]);
如果你需要只允许更新指定字段，可以使用

User::update(['name' => 'thinkphp', 'email' => 'thinkphp@qq.com'], ['id' => 1], ['name']);
上面的代码只会更新name字段的数据。

自动识别
我们已经看到，模型的新增和更新方法都是save方法，系统有一套默认的规则来识别当前的数据需要更新还是新增。

实例化模型后调用save方法表示新增；
查询数据后调用save方法表示更新；
不要在一个模型实例里面做多次更新，会导致部分重复数据不再更新，正确的方式应该是先查询后更新或者使用模型类的update方法更新。

不要调用save方法进行多次数据写入。

最佳实践
更新的最佳实践原则是：如果需要使用模型事件，那么就先查询后更新，如果不需要使用事件或者不查询直接更新，直接使用静态的Update方法进行条件更新，如非必要，尽量不要使用批量更新。
删除
模型的删除和数据库的删除方法区别在于，模型的删除会包含模型的事件处理。

删除当前模型
删除模型数据，可以在查询后调用delete方法。

$user = User::find(1);
$user->delete();
delete方法返回布尔值

根据主键删除
或者直接调用静态方法（根据主键删除）

User::destroy(1);
// 支持批量删除多个数据
User::destroy([1,2,3]);
当destroy方法传入空值（包括空字符串和空数组）的时候不会做任何的数据删除操作，但传入0则是有效的

条件删除
还支持使用闭包删除，例如：

User::destroy(function($query){
    $query->where('id','>',10);
});
或者通过数据库类的查询条件删除

User::where('id','>',10)->delete();
直接调用数据库的delete方法的话无法调用模型事件。

软删除
﻿
在实际项目中，对数据频繁使用删除操作会导致性能问题，软删除的作用就是把数据加上删除标记，而不是真正的删除，同时也便于需要的时候进行数据的恢复。

要使用软删除功能，需要引入SoftDelete trait，例如User模型按照下面的定义就可以使用软删除功能：

<?php
namespace app\model;
﻿
use think\Model;
use think\model\concern\SoftDelete;
﻿
class User extends Model
{
    use SoftDelete;
    protected $deleteTime = 'delete_time';
}
﻿
deleteTime属性用于定义你的软删除标记字段，ThinkORM的软删除字段使用时间类型，用于记录数据的删除时间。可以使用defaultSoftDelete属性来定义软删除字段的默认值，没有设置的话默认值为Null。

<?php
namespace app\model;
﻿
use think\Model;
use think\model\concern\SoftDelete;
﻿
class User extends Model
{
    use SoftDelete;
    protected $deleteTime = 'delete_time';
    protected $defaultSoftDelete = 0;
}
﻿

可以用类型转换指定软删除字段的类型，建议数据表的所有时间字段统一一种类型。

定义好模型后，我们就可以使用：

// 软删除
User::destroy(1);
// 真实删除
User::destroy(1,true);
﻿
$user = User::find(1);
// 软删除
$user->delete();
// 真实删除
$user->force()->delete();
﻿
默认情况下查询的数据不包含软删除数据，如果需要包含软删除的数据，可以使用下面的方式查询：

User::withTrashed()->find();
User::withTrashed()->select();
﻿
如果仅仅需要查询软删除的数据，可以使用：

User::onlyTrashed()->find();
User::onlyTrashed()->select();
﻿
恢复被软删除的数据

$user = User::onlyTrashed()->find(1);
$user->restore();
﻿

软删除的删除操作仅对模型的删除方法有效，如果直接使用数据库的删除方法则无效，例如下面的方式无效。

$user = new User;
$user->where('id',1)->delete();
﻿

最佳实践
删除的最佳实践原则是：如果删除当前模型数据，用delete方法，如果需要直接删除数据，使用destroy静态方法。
查询
模型查询和数据库查询方法的区别主要在于，模型中的查询的数据在获取的时候会经过获取器的处理，以及更加对象化的获取方式。

模型查询除了使用自身的查询方法外，一样可以使用数据库的查询构造器，返回的都是模型对象实例。但如果直接调用查询对象的方法，IDE可能无法完成自动提示。

获取单个数据
获取单个数据的方法包括：

// 取出主键为1的数据
$user = User::find(1);
echo $user->name;

// 使用查询构造器查询满足条件的数据
$user = User::where('name', 'thinkphp')->find();
echo $user->name;
模型使用find方法查询，如果数据不存在返回Null，否则返回当前模型的对象实例。如果希望查询数据不存在则返回一个空模型，可以使用。

$user = User::findOrEmpty(1);
你可以用isEmpty方法来判断当前是否为一个空模型。

$user = User::where('name', 'thinkphp')->findOrEmpty();
if (!$user->isEmpty()) {
    echo $user->name;
}
如果你是在模型内部获取数据，请不要使用$this->name的方式来获取数据，请使用$this->getAttr('name') 替代。

获取多个数据
取出多个数据：

// 根据主键获取多个数据
$list = User::select([1,2,3]);
// 对数据集进行遍历操作
foreach($list as $key=>$user){
    echo $user->name;
}
要更多的查询支持，一样可以使用查询构造器：

// 使用查询构造器查询
$list = User::where('status', 1)->limit(3)->order('id', 'asc')->select();
foreach($list as $key=>$user){
    echo $user->name;
}
查询构造器方式的查询可以支持更多的连贯操作，包括排序、数量限制等。

模型数据集
模型的select查询方法返回数据集对象 think\model\Collection，该对象继承自 think\Collection，因此具有普通数据集的所有方法，而且还提供了额外的模型操作方法。

基本用法和数组一样，例如可以遍历和直接获取某个元素。

// 模型查询返回数据集对象
$list = User::where('id', '>', 0)->select();
// 获取数据集的数量
echo count($list);
// 直接获取其中的某个元素
dump($list[0]);
// 遍历数据集对象
foreach ($list as $user) {
    dump($user);
}
// 删除某个元素
unset($list[0]);
需要注意的是，如果要判断数据集是否为空，不能直接使用empty判断，而必须使用数据集对象的isEmpty方法判断，例如：

$users = User::select();
if($users->isEmpty()){
    echo '数据集为空';
}
你可以使用模型的hidden/visible/append/withAttr方法进行数据集的输出处理，例如：

// 模型查询返回数据集对象
$list = User::where('id', '>', 0)->select();
// 对输出字段进行处理
$list->hidden(['password']) 
	->append(['status_text'])
    ->withAttr('name', function($value, $data) {
        return strtolower($value);
    });
dump($list);
如果需要对数据集的结果进行筛选，可以使用：

// 模型查询返回数据集对象
$list = User::where('id', '>', 0)->select()
    ->where('name', 'think')
    ->where('score', '>', 80);
dump($list);
支持whereLike/whereIn/whereBetween等快捷方法。

// 模型查询返回数据集对象
$list = User::where('id', '>', 0)->select()
    ->whereLike('name', 'think%')
    ->whereBetween('score', [80,100]);
dump($list);
支持数据集的order排序操作。

// 模型查询返回数据集对象
$list = User::where('id', '>', 0)->select()
    ->where('name', 'think')
    ->where('score', '>', 80)
    ->order('create_time','desc');
dump($list);
支持数据集的diff/intersect操作。

// 模型查询返回数据集对象
$list1 = User::where('status', 1)->field('id,name')->select();
$list2 = User::where('name', 'like', 'think')->field('id,name')->select();
// 计算差集
dump($list1->diff($list2));
// 计算交集
dump($list1->intersect($list2));
支持对数据集的数据进行批量删除和更新操作，例如：

$list = User::where('status', 1)->select();
$list->update(['name' => 'php']);

$list = User::where('status', 1)->select();
$list->delete();
自定义数据集对象
支持在模型中单独设置查询数据集的返回对象的名称，例如：

<?php
namespace app\index\model;

use think\Model;

class User extends Model
{
	// 设置返回数据集的对象名
	protected $resultSetType = '\app\common\Collection';
}
resultSetType属性用于设置自定义的数据集使用的类名，该类应当继承系统的 think\model\Collection 类。

使用查询构造器
在模型中仍然可以调用数据库的链式操作和查询方法，可以充分利用数据库的查询构造器的优势。

例如：

User::where('id',10)->find();
User::where('status',1)->order('id desc')->select();
User::where('status',1)->limit(10)->select();
使用查询构造器直接使用静态方法调用即可，无需先实例化模型。

获取某个字段或者某个列的值
// 获取某个用户的积分
User::where('id',10)->value('score');
// 获取某个列的所有值
User::where('status',1)->column('name');
// 以id为索引
User::where('status',1)->column('name','id');
value和column方法返回的不再是一个模型对象实例，而是纯粹的值或者某个列的数组。并且不支持获取器。

如果你希望支持模型的获取器和类型转换等处理，可以使用

// 获取某个用户的积分
User::where('id',10)->valueWithAttr('score');
// 获取某个列的所有值
User::where('status',1)->columnWithAttr('name');
// 以id为索引
User::where('status',1)->columnWithAttr('name','id');
动态查询
支持数据库的动态查询方法，例如：

// 根据name字段查询用户
$user = User::getByName('thinkphp');

// 根据email字段查询用户
$user = User::getByEmail('thinkphp@qq.com');
聚合查询
同样在模型中也可以调用数据库的聚合方法查询，例如：

User::count();
User::where('status','>',0)->count();
User::where('status',1)->avg('score');
User::max('score');
如果你的字段不是数字类型，在使用max/min的时候，需要加上第二个参数，表示不强制转化为数字。

User::max('name', false);
数据分批处理
模型也可以支持对返回的数据分批处理，这在处理大量数据的时候非常有用，例如：

User::chunk(100, function ($users) {
    foreach($users as $user){
        // 处理user模型对象
    }
});
使用游标查询
模型也可以使用数据库的cursor方法进行游标查询，返回生成器对象

foreach(User::where('status', 1)->cursor() as $user){
	echo $user->name;
}
user变量是一个模型对象实例。

最佳实践
模型查询的最佳实践原则是：在模型外部使用静态方法进行查询，内部使用动态方法查询，包括使用数据库的查询构造器。
查询范围
查询范围
对于一些常用的查询条件，我们可以事先定义好，以便快速调用，这个事先定义的查询条件方法有一个统一的前缀scope，我们称之为查询范围，例如下面给User模型定义了两个查询范围方法。

<?php
namespace app\model;

use think\Model;

class User extends Model
{

    public function scopeThinkphp($query)
    {
        $query->where('name','thinkphp')->field('id,name');
    }
    
    public function scopeAge($query)
    {
        $query->where('age','>',20)->limit(10);
    }    
    
}
就可以进行下面的条件查询：

// 查找name为thinkphp的用户
User::scope('thinkphp')->find();
// 查找年龄大于20的10个用户
User::scope('age')->select();
// 查找name为thinkphp的用户并且年龄大于20的10个用户
User::scope('thinkphp,age')->select();
查询范围的方法可以定义额外的参数，例如User模型类定义如下：

<?php
namespace app\model;

use think\Model;

class User extends Model
{
	public function scopeEmail($query, $email)
    {
    	$query->where('email', 'like', '%' . $email . '%');
    }
    
    public function scopeScore($query, $score)
    {
    	$query->where('score', '>', $score);
    }
    
}
在查询的时候可以如下使用：

// 查询email包含thinkphp和分数大于80的用户
User::email('thinkphp')->score(80)->select();
可以直接使用闭包函数进行查询，例如：

User::scope(function($query){
    $query->where('age','>',20)->limit(10);
})->select();
使用查询范围后，只能使用find或者select查询。

全局查询范围
支持在模型里面设置globalScope属性，定义全局的查询范围

<?php
namespace app\model;

use think\Model;

class User extends Model
{
    // 定义全局的查询范围
    protected $globalScope = ['status'];

    public function scopeStatus($query)
    {
        $query->where('status',1);
    }
}
然后，执行下面的代码：

$user = User::find(1);
最终的查询条件会是

status = 1 AND id = 1
如果需要动态关闭所有的全局查询范围，可以使用：

// 关闭全局查询范围
User::withoutGlobalScope()->select();
可以使用withoutGlobalScope方法动态关闭部分全局查询范围。

User::withoutGlobalScope(['status'])->select();
复制
只读字段
只读字段用来保护某些特殊的字段值不被更改，这个字段的值一旦写入，就无法更改。 要使用只读字段的功能，我们只需要在模型中定义readonly属性：

<?php
namespace app\model;

use think\Model;

class User extends Model
{
    protected $readonly = ['name', 'email'];
}
例如，上面定义了当前模型的name和email字段为只读字段，不允许被更改。也就是说当执行更新方法之前会自动过滤掉只读字段的值，避免更新到数据库。

下面举个例子说明下：

$user = User::find(5);
 // 更改某些字段的值
$user->name = 'TOPThink';
$user->email = 'Topthink@gmail.com';
$user->address = '上海静安区';
 // 保存更改后的用户数据
$user->save();
事实上，由于我们对name和email字段设置了只读，因此只有address字段的值被更新了，而name和email的值仍然还是更新之前的值。

支持动态设置只读字段，例如：

$user = User::find(5);
 // 更改某些字段的值
$user->name = 'TOPThink';
$user->email = 'Topthink@gmail.com';
$user->address = '上海静安区';
 // 保存更改后的用户数据
$user->readonly(['name','email'])->save();
只读字段仅针对模型的更新方法，如果使用数据库的更新方法则无效，例如下面的方式无效。

$user = new User;
 // 要更改字段值
$data['name'] = 'TOPThink';
$data['email'] = 'Topthink@gmail.com';
$data['address'] = '上海静安区';
 // 保存更改后的用户数据
$user->where('id', 5)->update($data);
复制
JSON字段
操作模型的JSON数据字段相比Db类要方便的多，首先需要在模型类中添加JSON字段定义。

<?php
namespace app\model;

use think\Model;
class User extends Model
{
	// 设置json类型字段
	protected $json = ['info'];
}
定义后，可以进行如下JSON数据操作。

写入JSON数据
使用数组方式写入JSON数据：

$user = new User;
$user->name = 'thinkphp';
$user->info = [
	'email'    => 'thinkphp@qq.com',
    'nickname '=> '流年',
];
$user->save();
使用对象方式写入JSON数据

$user = new User;
$user->name = 'thinkphp';
$info = new \StdClass();
$info->email = 'thinkphp@qq.com';
$info->nickname = '流年';
$user->info = $info;
$user->save();
查询JSON数据
$user = User::find(1);
echo $user->name; // thinkphp
echo $user->info->email; // thinkphp@qq.com
echo $user->info->nickname; // 流年
查询条件为JSON数据

$user = User::where('info->nickname','流年')->find();
echo $user->name; // thinkphp
echo $user->info->email; // thinkphp@qq.com
echo $user->info->nickname; // 流年
如果JSON数据为数组，可以这样查询

$user = User::where('info->[0]->nickname', '流年')->find();
或者使用whereJsonContains方法

$user = User::whereJsonContains('info', 'thinkphp')->find();
如果你需要查询的JSON属性是整型类型的话，可以在模型类里面定义JSON字段的属性类型，就会自动进行相应类型的参数绑定查询。

<?php
namespace app\model;

use think\Model;

class User extends Model
{
	// 设置json类型字段
	protected $json = ['info'];
    
    // 设置JSON字段的类型
    protected $jsonType = [
    	'info->user_id'	=>	'int'
    ];
}
没有定义类型的属性默认为字符串类型，因此字符串类型的属性可以无需定义。

可以设置模型的JSON数据返回数组，只需要在模型设置jsonAssoc属性为true。

<?php
namespace app\model;

use think\Model;

class User extends Model
{
	// 设置json类型字段
	protected $json = ['info'];
    
    // 设置JSON数据返回数组
    protected $jsonAssoc = true;
}
设置后，查询代码调整为：

$user = User::find(1);
echo $user->name; // thinkphp
echo $user->info['email']; // thinkphp@qq.com
echo $user->info['nickname']; // 流年
聚合查询
可以支持对JSON字段进行聚合查询

User::where('info->score', '>', 80)
    ->count('info->user_id');
更新JSON数据
$user = User::find(1);
$user->name = 'kancloud';
$user->info->email = 'kancloud@qq.com';
$user->info->nickname = 'kancloud';
$user->save();
如果设置模型的JSON数据返回数组，那么更新操作需要调整如下。

$user = User::find(1);
$user->name = 'kancloud';
$info['email'] = 'kancloud@qq.com';
$info['nickname'] = 'kancloud';
$user->info = $info;
$user->save();
复制
自动时间写入
系统支持自动写入创建和更新的时间戳字段（默认关闭），有两种方式配置支持。

第一种方式是全局开启，在数据库配置文件中进行设置：

// 开启自动写入时间戳字段
'auto_timestamp' => true,
第二种是在需要的模型类里面单独开启：

<?php
namespace app\model;

use think\Model;

class User extends Model
{
    protected $autoWriteTimestamp = true;
}
又或者首先在数据库配置文件中全局开启，然后在个别不需要使用自动时间戳写入的模型类中单独关闭：

<?php
namespace app\model;

use think\Model;

class User extends Model
{
    protected $autoWriteTimestamp = false;
}
一旦配置开启的话，会自动写入create_time和update_time两个字段的值，并且自动识别时间字段的类型，为了提高性能，也可以直接设置时间字段的类型：

// 开启自动写入时间戳字段
'auto_timestamp' => 'datetime',
或者

<?php
namespace app\model;

use think\Model;

class User extends Model
{
    protected $autoWriteTimestamp = 'datetime';
}
默认的创建时间字段为create_time，更新时间字段为update_time，支持的字段类型包括timestamp/datetime/int。

写入数据的时候，系统会自动写入create_time和update_time字段，而不需要定义修改器，例如：

$user = new User();
$user->name = 'thinkphp';
$user->save();
echo $user->create_time; // 输出类似 2016-10-12 14:20:10
echo $user->update_time; // 输出类似 2016-10-12 14:20:10
时间字段的自动写入仅针对模型的写入方法，如果使用数据库的更新或者写入方法则无效。

时间字段输出的时候会自动进行格式转换，如果不希望自动格式化输出，可以把数据库配置文件的 datetime_format 参数值改为false

datetime_format参数支持设置为一个时间类名，这样便于你进行更多的时间处理，例如：

// 设置时间字段的格式化类
'datetime_format' => '\org\util\DateTime',
该类应该包含一个__toString方法定义以确保能正常写入数据库。

如果你的数据表字段不是默认值的话，可以按照下面的方式定义：

<?php
namespace app\model;

use think\Model;

class User extends Model 
{
    // 定义时间戳字段名
    protected $createTime = 'create_at';
    protected $updateTime = 'update_at';
}
下面是修改字段后的输出代码：

$user = new User();
$user->name = 'thinkphp';
$user->save();
echo $user->create_at; // 输出类似 2016-10-12 14:20:10
echo $user->update_at; // 输出类似 2016-10-12 14:20:10
如果你只需要使用create_time字段而不需要自动写入update_time，则可以单独关闭某个字段，例如：

namespace app\model;

use think\Model;

class User extends Model 
{
    // 关闭自动写入update_time字段
    protected $updateTime = false;
}
支持动态关闭时间戳写入功能，例如你希望更新阅读数的时候不修改更新时间，可以使用isAutoWriteTimestamp方法：

$user = User::find(1);
$user->read +=1;
$user->isAutoWriteTimestamp(false)->save();
复制
获取器
获取器
﻿获取器的作用是对模型实例的（原始）数据做出自动处理。一个获取器对应模型的一个特殊方法，方法命名规范为：

getFieldNameAttr
FieldName为数据表字段的驼峰转换，定义了获取器之后会在下列情况自动触发：

模型的数据对象取值操作（$model->field_name）；
模型的序列化输出操作（$model->toArray()及toJson()）；
显式调用getAttr方法（$this->getAttr('field_name')）；
获取器的场景包括：﻿
时间日期字段的格式化输出；
集合或枚举类型的输出；
数字状态字段的输出；
组合字段的输出；

例如，我们需要对状态值进行转换，可以使用：
<?php
namespace app\model;
﻿
use think\Model;
﻿
class User extends Model 
{
    public function getStatusAttr($value)
    {
        $status = [-1=>'删除',0=>'禁用',1=>'正常',2=>'待审核'];
        return $status[$value];
    }
}
数据表的字段会自动转换为驼峰法，一般status字段的值采用数值类型，我们可以通过获取器定义，自动转换为字符串描述。

$user = User::find(1);
echo $user->status; // 例如输出“正常”
﻿获取器还可以定义数据表中不存在的字段，例如：

<?php
namespace app\model;
﻿
use think\Model;
﻿
class User extends Model 
{
    public function getStatusTextAttr($value,$data)
    {
        $status = [-1=>'删除',0=>'禁用',1=>'正常',2=>'待审核'];
        return $status[$data['status']];
    }
}
获取器方法的第二个参数传入的是当前的所有数据数组。

我们就可以直接使用status_text字段的值了，例如：

$user = User::find(1);
echo $user->status_text; // 例如输出“正常”
﻿获取原始数据
如果你定义了获取器的情况下，希望获取数据表中的原始数据，可以使用：

$user = User::find(1);
// 通过获取器获取字段
echo $user->status;
// 获取原始字段数据
echo $user->getData('status');
// 获取全部原始数据
dump($user->getData());
动态获取器﻿
可以支持对模型使用动态获取器，无需在模型类中定义获取器方法。

User::withAttr('name', function($value, $data) {
	return strtolower($value);
})->select();
withAttr方法支持多次调用，定义多个字段的获取器。另外注意，withAttr方法之后不能再使用模型的查询方法，必须使用Db类的查询方法。动态获取器会在模型输出的时候自动追加，无需手动调用append方法。

如果同时还在模型里面定义了相同字段的获取器，则动态获取器优先，也就是可以临时覆盖定义某个字段的获取器。

支持对关联模型的字段使用动态获取器，例如：

User::with('profile')->withAttr('profile.name', function($value, $data) {
	return strtolower($value);
})->select();
注意：对于MorphTo关联不支持使用动态获取器。

并且支持对JSON字段使用获取器，例如在模型中定义了JSON字段的话：

<?php
namespace app\index\model;
﻿
use think\Model;
﻿
class User extends Model
{
	// 设置json类型字段
	protected $json = ['info'];
}
﻿
可以使用下面的代码定义JSON字段的获取器。

User::withAttr('info.name', function($value, $data) {
	return strtolower($value);
})->select();
最新版本已经支持对column和value查询方法使用获取器。
修改器
修改器
和获取器相反，修改器的主要作用是对模型设置的数据对象值进行处理。

修改器方法的命名规范为：

setFieldNameAttr
修改器的使用场景和读取器类似：

时间日期字段的转换写入；
集合或枚举类型的写入；
数字状态字段的写入；
某个字段涉及其它字段的条件或者组合写入；
定义了修改器之后会在下列情况下触发：

模型对象赋值；
调用模型的data方法，并且第二个参数传入true；
调用模型的save方法，并且传入数据；
显式调用模型的setAttr方法；
例如：

<?php
namespace app\model;

use think\Model;

class User extends Model 
{
    public function setNameAttr($value)
    {
        return strtolower($value);
    }
}
如下代码实际保存到数据库中的时候会转为小写

$user = new User();
$user->name = 'THINKPHP';
$user->save();
echo $user->name; // thinkphp
也可以进行序列化字段的组装：

namespace app\model;

use think\Model;

class User extends Model 
{
    public function setSerializeAttr($value,$data)
    {
        return serialize($data);
    }
}
修改器方法的第二个参数会自动传入当前的所有数据数组。

如果你需要在修改器中修改其它数据，可以使用

<?php
namespace app\model;

use think\Model;

class User extends Model 
{
    public function setTestFieldAttr($value, $data)
    {
        $this->set('other_field', $data['some_field']);
    }
}
上面的例子，在test_field字段的修改器中修改了other_field字段数据，并且没有返回值（表示不对test_field字段做任何修改）。

批量修改
除了赋值的方式可以触发修改器外，还可以用下面的方法批量触发修改器：

$user = new User();
$data['name'] = 'THINKPHP';
$data['email'] = 'thinkphp@qq.com';
$user->data($data, true);
$user->save();
echo $user->name; // thinkphp
如果为name和email字段都定义了修改器的话，都会进行处理。

或者直接使用save方法触发，例如：

$user = new User();
$data['name'] = 'THINKPHP';
$data['email'] = 'thinkphp@qq.com';
$user->save($data);
echo $user->name; // thinkphp
修改器方法仅对模型的写入方法有效，调用数据库的写入方法写入无效，例如下面的方式修改器无效。

$user = new User();
$data['name'] = 'THINKPHP';
$data['email'] = 'thinkphp@qq.com';
$user->insert($data);
搜索器
搜索器
搜索器的作用是用于封装字段（或者搜索标识）的查询条件表达式，一个搜索器对应一个特殊的方法（该方法必须是public类型），方法命名规范为：

searchFieldNameAttr
FieldName为数据表字段的驼峰转换，搜索器仅在调用withSearch方法的时候触发。

搜索器的场景包括：

限制和规范表单的搜索条件；
预定义查询条件简化查询；
例如，我们需要给User模型定义name字段和时间字段的搜索器，可以使用：

<?php
namespace app\model;

use think\Model;

class User extends Model 
{
    public function searchNameAttr($query, $value, $data)
    {
        $query->where('name','like', $value . '%');
    }
    
    public function searchCreateTimeAttr($query, $value, $data)
    {
        $query->whereBetweenTime('create_time', $value[0], $value[1]);
    }    
}
然后，我们可以使用下面的查询

User::withSearch(['name','create_time'], [
		'name'			=>	'think',
    	'create_time'	=>	['2018-8-1','2018-8-5'],
        'status'		=>	1
    ])
	->select();
默认情况下，搜索器会首先检查数据是否存在，最终生成的SQL语句类似于

SELECT * FROM `think_user` WHERE  `name` LIKE 'think%' AND `create_time` BETWEEN '2018-08-01 00:00:00' AND '2018-08-05 00:00:00' 
可以看到查询条件中并没有status字段的数据，因此可以很好的避免表单的非法查询条件传入，在这个示例中仅能使用name和create_time条件进行查询。

事实上，除了在搜索器中使用查询表达式外，还可以使用其它的任何查询构造器以及链式操作。

例如，你需要通过表单定义的排序字段进行搜索结果的排序，可以使用

<?php
namespace app\model;

use think\Model;

class User extends Model 
{
    public function searchNameAttr($query, $value, $data)
    {
        $query->where('name','like', $value . '%');
        if (isset($data['sort'])) {
        	$query->order($data['sort']);
        }        
    }
    
    public function searchCreateTimeAttr($query, $value, $data)
    {
        $query->whereBetweenTime('create_time', $value[0], $value[1]);
    }      
}
然后，我们可以使用下面的查询

User::withSearch(['name','create_time', 'status'], [
		'name'			=>	'think',
    	'create_time'	=>	['2018-8-1','2018-8-5'],
        'status'		=>	1,
        'sort'			=>	['status'=>'desc'],
    ])
	->select();
最终查询的SQL可能是

SELECT * FROM `think_user` WHERE  `name` LIKE 'think%' AND `create_time` BETWEEN '2018-08-01 00:00:00' AND '2018-08-05 00:00:00' ORDER BY `status` DESC
你可以给搜索器定义字段别名，例如：

User::withSearch(['name'=>'nickname','create_time', 'status'], [
		'nickname'		=>	'think',
    	'create_time'	=>	['2018-8-1','2018-8-5'],
        'status'		=>	1,
        'sort'			=>	['status'=>'desc'],
    ])
	->select();
搜索器通常会和查询范围进行比较，搜索器无论定义了多少，只需要一次调用，查询范围如果需要组合查询的时候就需要多次调用。
字段映射
字段映射
可以统一定义模型属性的字段映射，例如下面的定义把数据表的name字段映射为模型的nickname属性。

<?php
namespace app\model;

use think\Model;

class User extends Model 
{
    protected $mapping = [
        'name'    =>    'nickname', // 数据表的name字段映射为模型的nickname属性
        ...
    ];
}
查询User模型数据后获取该属性或模型输出的时候，会自动处理映射字段。

$user = User::find(1);
echo $user->nickname; 
dump($user->toArray());
写入或更新数据的时候，也会自动处理映射字段。

$user = User::find(1);
$user->nickname = 'new nickname';
$user->save();
注意：字段映射后获取和设置映射字段的值的时候，字段名必须和映射名保持一致，系统不会自动进行驼峰转换。

也可以在查询的时候动态设置字段映射

User::where('status', 1)->select()->mapping(['name' => 'nickname']);
复制
类型转换
支持给字段设置类型自动转换，会在写入和读取的时候自动进行类型转换处理，例如：

<?php
namespace app\model;

use think\Model;

class User extends Model 
{
    protected $type = [
        'status'    =>  'integer',
        'score'     =>  'float',
        'birthday'  =>  'datetime',
        'info'      =>  'array',
    ];
}
下面是一个类型自动转换的示例：

$user = new User;
$user->status = '1';
$user->score = '90.50';
$user->birthday = '2015/5/1';
$user->info = ['a'=>1,'b'=>2];
$user->save();
var_dump($user->status); // int 1
var_dump($user->score); // float 90.5;
var_dump($user->birthday); // string '2015-05-01 00:00:00'
var_dump($user->info);// array (size=2) 'a' => int 1  'b' => int 2
数据库查询默认取出来的数据都是字符串类型，如果需要转换为其他的类型，需要设置，支持的类型包括如下类型：

integer
设置为integer（整型）后，该字段写入和输出的时候都会自动转换为整型。

float
该字段的值写入和输出的时候自动转换为浮点型。

boolean
该字段的值写入和输出的时候自动转换为布尔型。

array
如果设置为强制转换为array类型，系统会自动把数组编码为json格式字符串写入数据库，取出来的时候会自动解码。

object
该字段的值在写入的时候会自动编码为json字符串，输出的时候会自动转换为stdclass对象。

serialize
指定为序列化类型的话，数据会自动序列化写入，并且在读取的时候自动反序列化。

json
指定为json类型的话，数据会自动json_encode写入，并且在读取的时候自动json_decode处理。

timestamp
指定为时间戳字段类型的话，该字段的值在写入时候会自动使用strtotime生成对应的时间戳，输出的时候会自动转换为dateFormat属性定义的时间字符串格式，默认的格式为Y-m-d H:i:s，如果希望改变其他格式，可以定义如下：

<?php
namespace app\model;

use think\Model;

class User extends Model 
{
    protected $dateFormat = 'Y/m/d';
    protected $type = [
        'status'    =>  'integer',
        'score'     =>  'float',
        'birthday'  =>  'timestamp',
    ];
}
或者在类型转换定义的时候使用：

<?php
namespace app\model;

use think\Model;

class User extends Model 
{
    protected $type = [
        'status'    =>  'integer',
        'score'     =>  'float',
        'birthday'  =>  'timestamp:Y/m/d',
    ];
}
然后就可以

$user = User::find(1);
echo $user->birthday; // 2015/5/1
datetime
和timestamp类似，区别在于写入和读取数据的时候都会自动处理成时间字符串Y-m-d H:i:s的格式。

枚举类型（PHP8.1+版本支持）
你可以给字段定义枚举类型（仅支持回退枚举）

<?php
namespace app\enum;

Enum Status : int
{
	case Normal = 1;
	case Disabled = 0;
	case Pending  = 2;
}
然后，在模型里面定义类型为枚举

<?php
namespace app\model;

use app\enum\Status;
use think\Model;

class User extends Model 
{
    protected $type = [
        'status'    =>  Status::class,
    ];
}
写入的时候会自动获取枚举的value值写入数据库，读取的时候会自动转换为枚举实例（方便调用枚举自定义方法）。

$user         = new User;
$user->name   = 'thinkphp';
$user->status = Status::Normal; // 实际写入数据值为 1
$user->save();

$user = User::find(1);
dump($user->status); // 输出Status枚举对象
如果希望读取的时候自动转换为枚举实例的name数据，可以开启enumReadName属性。

<?php
namespace app\model;

use app\enum\Status;
use think\Model;

class User extends Model 
{
    protected $type = [
        'status'    =>  Status::class,
    ];
    protected $enumReadName = true;
}
$user = User::find(1);
dump($user->status); // 输出 Normal
如果设置为字符串，则表示使用自动调用枚举类的方法输出。

<?php
namespace app\model;

use app\enum\Status;
use think\Model;

class User extends Model 
{
    protected $type = [
        'status'    =>  Status::class,
    ];
    protected $enumReadName = 'value';
}
表示使用枚举类的value方法输出，或使用EnumTransform接口实现value方法自定义输出转换需求。

<?php
namespace app\enum;

use think\model\contract\EnumTransform;

Enum Status : int implements EnumTransform
{
	case Normal = 1;
	case Disabled = 0;
	case Pending  = 2;

	public function value()
	{
		return match($this) {
			Status::Normal => '正常',
			Status::Disabled => '禁用',
			Status::Pending  => '待审核',
		};
	}
}
$user = User::find(1);
dump($user->status); // 输出 正常
对象类型转换
支持使用对象类名作为类型转换，需要满足下面几个条件之一：

该类具有think\model\contract\FieldTypeTransform接口实现（优先级最高）
该类使用枚举类（参考上面枚举类型）
该类具有__toString方法实现并且架构函数可以传值
模型输出
模型输出
模型数据的模板输出可以直接把模型对象实例赋值给模板变量，在模板中可以直接输出，例如：

<?php
namespace app\controller;

use app\model\User;
use think\facade\View;

class Index
{
    public function index()
    {
        $user = User::find(1);
        View::assign('user', $user);
        
        return View::fetch();
    }
}
在模板文件中可以使用

{$user.name}
{$user.email}
模板中的模型数据输出一样会调用获取器。

数组转换
可以使用toArray方法将当前的模型实例输出为数组，例如：

$user = User::find(1);
dump($user->toArray());
支持设置不输出的字段属性：

$user = User::find(1);
dump($user->hidden(['create_time','update_time'])->toArray());
数组输出的字段值会经过获取器的处理，如果不在数据表字段列表中的字段属性需要输出，必须使用append方法附加属性，例如：

$user = User::find(1);
dump($user->append(['status_text'])->toArray());
支持设置允许输出的属性，例如：

$user = User::find(1);
dump($user->visible(['id','name','email'])->toArray());
对于数据集结果一样可以直接使用（包括append、visible和hidden方法）

$list = User::select();
$list = $list->toArray();
可以在查询之前定义hidden/visible/append方法，例如：

dump(User::where('id',10)->hidden(['create_time','update_time'])->append(['status_text'])->find()->toArray());
注意，必须要首先调用一次Db类的方法后才能调用hidden/visible/append方法。

JSON序列化
可以调用模型的toJson方法进行JSON序列化，toJson方法的使用和toArray一样。

$user = User::find(1);
echo $user->toJson();
可以设置需要隐藏的字段，例如：

$user = User::find(1);
echo $user->hidden(['create_time','update_time'])->toJson();
或者追加其它的字段（该字段必须有定义获取器）：

$user = User::find(1);
echo $user->append(['status_text'])->toJson();
设置允许输出的属性：

$user = User::find(1);
echo $user->visible(['id','name','email'])->toJson();
模型对象可以直接被JSON序列化，例如：

echo json_encode(User::find(1));
输出结果类似于：

{"id":"1","name":"","title":"","status":"1","update_time":"1430409600","score":"90.5"}
如果直接echo 一个模型对象会自动调用模型的toJson方法输出，例如：

echo User::find(1);
输出的结果和上面是一样的。
模型事件
模型事件
模型事件是指在进行模型的查询和写入操作的时候触发的操作行为。

模型事件只在调用模型的方法生效，使用Db查询构造器操作是无效的

模型支持如下事件：

事件	描述	事件方法名
AfterRead	查询后	onAfterRead
BeforeInsert	新增前	onBeforeInsert
AfterInsert	新增后	onAfterInsert
BeforeUpdate	更新前	onBeforeUpdate
AfterUpdate	更新后	onAfterUpdate
BeforeWrite	写入前	onBeforeWrite
AfterWrite	写入后	onAfterWrite
BeforeDelete	删除前	onBeforeDelete
AfterDelete	删除后	onAfterDelete
BeforeRestore	恢复前	onBeforeRestore
AfterRestore	恢复后	onAfterRestore
注册的回调方法支持传入一个参数（当前的模型对象实例），但支持依赖注入的方式增加额外参数。

如果before_write、before_insert、 before_update 、before_delete事件方法中返回false或者抛出think\exception\ModelEventException异常的话，则不会继续执行后续的操作。

模型事件定义
最简单的方式是在模型类里面定义静态方法来定义模型的相关事件响应。

<?php
namespace app\model;

use think\Model;
use app\model\Profile;

class User extends Model
{
    public static function onBeforeUpdate($user)
    {
    	if ('thinkphp' == $user->name) {
        	return false;
        }
    }
    
    public static function onAfterDelete($user)
    {
		Profile::destroy($user->id);
    }
}
参数是当前的模型对象实例，支持使用依赖注入传入更多的参数。

如果是在ThinkPHP中使用的话，还可以支持直接通过事件监听和订阅。

Event::listen('app\model\User.BeforeUpdate', function($user) {
    // 
});
Event::listen('app\model\User.AfterDelete', function($user) {
    // 
});
模型观察者
可以注册模型事件观察者，把模型事件统一管理，无需在模型中定义事件响应。

<?php
namespace app\observer;

use app\model\User;

class UserObserver 
{
    public function onBeforeUpdate(User $user)
    {
    }
    
    public function onAfterDelete(User $user)
    {
    }
}
然后在模型中设置观察者

<?php
namespace app\model;

use think\Model;
use app\model\Profile;
use app\observer\UserObserver;

class User extends Model
{
    protected $eventObserver = UserObserver::class;
}
虚拟模型
虚拟模型
虚拟模型不会写入数据库，数据只能保存在内存中，而且只能通过实例化的方式来创建数据，虚拟模型可以保留模型的大部分功能，包括获取器、模型事件，甚至是关联操作。

要使用虚拟模型，只需要在模型定义的时候引入Virtual trait，例如：

<?php
namespace app\model;

use think\Model;
use think\model\concern\Virtual;

class User extends Model
{
    use Virtual;

    public function blog()
    {
        return $this->hasMany('Blog');
    }
}
你不需要在数据库中定义user表，但仍然可以进行相关数据操作，下面是一些例子。

// 创建数据
$user = User::create($data);
// 修改数据
$user->name = 'thinkphp';
$user->save();
// 获取关联数据
$blog = $user->blog()->limit(3)->select();
// 删除数据（同时删除关联blog数据）
$user->together(['blog'])->delete();
由于虚拟模型没有实际的数据表，所以你不能进行查询操作，下面的代码就会抛出异常

User::find(1);
// 会抛出下面的异常
// virtual model not support db query
另外，注意，虚拟模型不再支持自动时间戳功能，如果需要时间字段需要在实例化的时候传入。
关联
模型关联
通过模型关联操作把数据表的关联关系对象化，解决了大部分常用的关联场景，封装的关联操作比起常规的数据库联表操作更加智能和高效，并且直观。

避免在模型内部使用复杂的join查询和视图查询。

从面向对象的角度来看关联的话，模型的关联其实应该是模型的某个属性，比如用户的档案关联，就应该是下面的情况：

// 获取用户模型实例
$user = User::find(1);
// 获取用户的档案
$user->profile;
// 获取用户的档案中的手机资料
$user->profile->mobile;
为了更方便和灵活的定义模型的关联关系，框架选择了方法定义而不是属性定义的方式，每个关联属性其实是对应了一个模型的（关联）方法，这个关联属性和模型的数据一样是动态的，并非模型类的实体属性。

例如上面的关联属性就是在User模型类中定义了一个profile方法（mobile属性是Profile模型的属性）：

<?php

namespace app\model;

use think\Model;

class User extends Model
{
	public function profile()
    {
    	return $this->hasOne(Profile::class);
    }
}
一个模型可以定义多个不同的关联，增加不同的关联方法即可

同时，我们必须定义一个Profile模型（即使是一个空模型）。

<?php

namespace app\model;

use think\Model;

class Profile extends Model
{
}
关联方法返回的是不同的关联对象，例如这里的profile方法返回的是一个HasOne关联对象（think\model\relation\HasOne）实例。

当我们访问User模型对象实例的profile属性的时候，其实就是调用了profile方法来完成关联查询。

按照PSR-2规范，模型的方法名都是驼峰命名的，所以系统做了一个兼容处理，如果我们定义了一个userProfile的关联方法的时候，在获取关联属性的时候，下面两种方式都是有效的：

$user->userProfile;
$user->user_profile; // 建议使用
推荐关联属性统一使用后者，和数据表的字段命名规范一致，因此在很多时候系统自动获取关联属性的时候采用的也是后者。

可以简单的理解为关联定义就是在模型类中添加一个方法（注意不要和模型的对象属性以及其它业务逻辑方法冲突），一般情况下无需任何参数，并在方法中指定一种关联关系，比如上面的hasOne关联关系，支持的关联关系包括下面8种：

模型方法	关联类型
hasOne	一对一
belongsTo	一对一
hasMany	一对多
hasOneThrough	远程一对一
hasManyThrough	远程一对多
belongsToMany	多对多
morphMany	多态一对多
morphOne	多态一对一
morphTo	多态
关联方法的第一个参数就是要关联的模型名称，也就是说当前模型的关联模型必须也是已经定义好的一个模型。

两个模型之间因为参照模型的不同就会产生相对的但不一定相同的关联关系，并且相对的关联关系只有在需要调用的时候才需要定义，下面是每个关联类型的相对关联关系对照：

类型	关联关系	相对的关联关系
一对一	hasOne	belongsTo
一对多	hasMany	belongsTo
多对多	belongsToMany	belongsToMany
远程一对多	hasManyThrough	hasOneThrough
多态一对一	morphOne	morphTo
多态一对多	morphMany	morphTo
除此之外，关联定义的几个要点必须了解：

关联方法必须使用驼峰法命名；
关联方法一般无需定义任何参数；
关联调用的时候驼峰法和小写+下划线都支持；
关联字段设计尽可能按照规范可以简化关联定义；
关联方法定义可以添加额外查询条件；
例如，Profile模型中就可以定义一个相对的关联关系。

<?php

namespace app\model;

use think\Model;

class Profile extends Model
{
	public function user()
    {
    	return $this->belongsTo(User::class);
    }
}
在进行关联查询的时候，也是类似，只是当前模型不同。

// 获取档案实例
$profile = Profile::find(1);
// 获取档案所属的用户名称
echo $profile->user->name;
如果是数据集查询的话，关联获取的用法如下：

// 获取档案实例
$profiles = Profile::where('id', '>', 1)->select();
foreach($profiles as $profile) {
	// 获取档案所属的用户名称
	echo $profile->user->name;
}
如果你需要对关联模型进行更多的查询约束，可以在关联方法的定义方法后面追加额外的查询链式方法（但切忌不要滥用，并且不要使用实际的查询方法），例如：

<?php

namespace app\model;

use think\Model;

class User extends Model
{
	public function book()
    {
    	return $this->hasMany(Book::class)->order('pub_time');
    }
}
模型关联的优势主要在于查询，关联写入的实现和用单独的模型完成区别并不大。
一对一关联
一对一关联的场景比较常见，比如每个用户都有一个身份证，每个国家都有一个首都，这种关联我们称为HasOne关联。通常一对一关联的反向关联也是一对一关系，比如一个身份证属于一个用户，一个首都属于一个国家，这种反向一对一关联我们成为BelongsTo关联。

关联定义
定义一对一关联，例如，一个用户都有一个个人资料，我们定义User模型如下：

<?php
namespace app\model;

use think\Model;

class User extends Model
{
    public function profile()
    {
        return $this->hasOne(Profile::class);
    }
}
hasOne方法的参数包括：

hasOne('关联模型类名', '外键', '主键');
除了关联模型外，其它参数都是可选。

关联模型（必须）：关联模型类名
外键：默认的外键规则是当前模型名（不含命名空间，下同）+_id ，例如user_id
主键：当前模型主键，默认会自动获取也可以指定传入
一对一关联定义的时候还支持额外的方法，包括：

方法名	描述
bind	绑定关联属性到父模型
joinType	JOIN方式查询的JOIN方式，默认为INNER
如果使用了JOIN方式的关联查询方式，你可以在额外的查询条件中使用关联对象名（不含命名空间）作为表的别名。

关联查询
定义好关联之后，就可以使用下面的方法获取关联数据：

$user = User::find(1);
// 输出Profile关联模型的email属性
echo $user->profile->email;
默认情况下， 我们使用的是user_id 作为外键关联，如果不是的话则需要在关联定义的时候指定，例如：

<?php
namespace app\model;

use think\Model;

class User extends Model 
{
    public function profile()
    {
        return $this->hasOne(Profile::class, 'uid');
    }
}
有一点需要注意的是，关联方法的命名规范是驼峰法，而关联属性则一般是小写+下划线的方式，系统在获取的时候会自动转换对应，读取user_profile关联属性则对应的关联方法应该是userProfile。

根据关联数据查询
可以根据关联条件来查询当前模型对象数据，例如：

// 查询用户昵称是think的用户
// 注意第一个参数是关联方法名（不是关联模型名）
$users = User::hasWhere('profile', ['nickname'=>'think'])->select();

// 可以使用闭包查询
$users = User::hasWhere('profile', function($query) {
	$query->where('nickname', 'like', 'think%');
})->select();
注意：如果hasWhere需要和where同时使用的话，hasWhere必须在前面。

预载入查询
可以使用预载入查询解决典型的N+1查询问题，使用：

$users = User::with('profile')->select();
foreach ($users as $user) {
	echo $user->profile->name;
}
上面的代码使用的是IN查询，只会产生2条SQL查询。

如果要对关联模型进行约束，可以使用闭包的方式。

$users = User::with(['profile'	=> function($query) {
	$query->field('id,user_id,name,email');
}])->select();

foreach ($users as $user) {
	echo $user->profile->name;
}
with方法可以传入数组，表示同时对多个关联模型（支持不同的关联类型）进行预载入查询。

$users = User::with(['profile','book'])->select();
foreach ($users as $user) {
	echo $user->profile->name;
    foreach($user->book as $book) {
    	echo $book->name;
    }
}
默认情况下，关联查询的数据是不包含软删除数据的，如果需要包含软删除数据，可以在关联定义的时候或预载入查询的闭包方法里面使用withTrashed()方法。

$users = User::with(['profile'	=> function(Query $query) {
	$query->withTrashed();
}])->select();
如果需要在关联查询的时候指定不需要的全局查询范围，可以使用withoutScope()方法。

$users = User::with(['profile'	=> function(Query $query) {
	$query->withoutScope(['age']);
}])->select();
一对一关联预载入查询默认使用IN查询，如果需要使用JOIN方式的查询，使用withJoin方法，例如：

$users = User::withJoin('profile')->select();
foreach ($users as $user) {
	echo $user->profile->name;
}
withJoin方法默认使用的是INNER JOIN方式，如果需要使用其它的，可以改成

$users = User::withJoin('profile', 'LEFT')->select();
foreach ($users as $user) {
	echo $user->profile->name;
}
需要注意的是withJoin方式不支持嵌套关联，通常你可以直接传入多个需要关联的模型。

如果需要约束关联字段，必须在闭包中使用withField方法（field方法无效）

$users = User::withJoin(['profile'	=>	function($query) {
    $query->withField(['user_id', 'name', 'email']);
}])->select();
如果仅仅需要约束关联字段，可以使用下面的简便方法。

$users = User::withJoin([
	'profile'	=>	['user_id', 'name', 'email']
])->select();
该用法仅限于withJoin方法。

关联保存
$user = User::find(1);
// 如果还没有关联数据 则进行新增
$user->profile()->save(['email' => 'thinkphp']);
系统会自动把当前模型的主键传入Profile模型。

和新增一样使用save方法进行更新关联数据。

$user = User::find(1);
$user->profile->email = 'thinkphp';
$user->profile->save();
// 或者
$user->profile->save(['email' => 'thinkphp']);
相对关联
我们可以在Profile模型中定义一个相对的关联关系，例如：

<?php
namespace app\model;

use think\Model;

class Profile extends Model 
{
    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
belongsTo的参数包括：

belongsTo('关联模型','外键', '关联主键');
除了关联模型外，其它参数都是可选。

关联模型（必须）：关联模型类名
外键：当前模型外键，默认的外键名规则是关联模型名+_id
关联主键：关联模型主键，一般会自动获取也可以指定传入
默认的关联外键是user_id，如果不是，需要在第二个参数定义

<?php
namespace app\model;

use think\Model;

class Profile extends Model 
{
    public function user()
    {
        return $this->belongsTo(User::class, 'uid');
    }
}
我们就可以根据档案资料来获取用户模型的信息

$profile = Profile::find(1);
// 输出User关联模型的属性
echo $profile->user->account;
绑定属性到父模型
可以在定义关联的时候使用bind方法绑定属性到父模型，例如：

<?php
namespace app\model;

use think\Model;

class User extends Model 
{
    public function profile()
    {
        return $this->hasOne(Profile::class, 'uid')->bind(['nickname', 'email']);
    }
}
或者指定绑定属性别名

<?php
namespace app\model;

use think\Model;

class User extends Model 
{
    public function profile()
    {
        return $this->hasOne(Profile::class, 'uid')->bind([
        		'email',
                'truename'	=> 'nickname',
            ]);
    }
}
然后使用关联预载入查询的时候，可以使用

$user = User::with('profile')->find(1);
// 直接输出Profile关联模型的绑定属性
echo $user->email;
echo $user->truename;
绑定关联模型的属性支持读取器。

如果不是预载入查询，请使用模型的appendRelationAttr方法追加属性。

也可以使用动态绑定关联属性，可以使用

$user = User::find(1)->bindAttr('profile',['email','nickname']);
// 输出Profile关联模型的email属性
echo $user->email;
echo $user->nickname;
同样支持指定属性别名

$user = User::find(1)->bindAttr('profile',[
	'email',
    'truename'	=> 'nickname',
]);
// 输出Profile关联模型的email属性
echo $user->email;
echo $user->truename;
关联自动写入
我们可以使用together方法更方便的进行关联自动写入操作。

写入

$blog = new Blog;
$blog->name = 'thinkphp';
$blog->title = 'ThinkPHP5关联实例';
$content = new Content;
$content->data = '实例内容';
$blog->content = $content;
$blog->together(['content'])->save();
如果绑定了子模型的属性到当前模型，可以指定子模型的属性

$blog = new Blog;
$blog->name = 'thinkphp';
$blog->title = 'ThinkPHP5关联实例';
$blog->content = '实例内容';
// title和content是子模型的属性
$blog->together(['content'=>['title','content']])->save();
更新

// 查询
$blog = Blog::find(1);
$blog->title = '更改标题';
$blog->content->data = '更新内容';
// 更新当前模型及关联模型
$blog->together(['content'])->save();
删除

// 查询
$blog = Blog::with('content')->find(1);
// 删除当前及关联模型
$blog->together(['content'])->delete();
一对多关联
关联定义
一对多关联的情况也比较常见，使用hasMany方法定义，参数包括：

hasMany('关联模型','外键','主键');
除了关联模型外，其它参数都是可选。

关联模型（必须）：关联模型类名
外键：关联模型外键，默认的外键名规则是当前模型名+_id
主键：当前模型主键，一般会自动获取也可以指定传入
例如一篇文章可以有多个评论

<?php
namespace app\model;

use think\Model;

class Article extends Model 
{
    public function comments()
    {
        return $this->hasMany(Comment::class);
    }
}
同样，也可以定义外键的名称

<?php
namespace app\model;

use think\Model;

class Article extends Model 
{
    public function comments()
    {
        return $this->hasMany(Comment::class,'art_id');
    }
}
关联查询
我们可以通过下面的方式获取关联数据

$article = Article::find(1);
// 获取文章的所有评论
dump($article->comments);
// 也可以进行条件搜索
dump($article->comments()->where('status',1)->select());
根据关联条件查询
可以根据关联条件来查询当前模型对象数据，例如：

// 查询评论超过3个的文章
$list = Article::has('comments','>',3)->select();
// 查询评论状态正常的文章
$list = Article::hasWhere('comments',['status'=>1])->select();
如果需要更复杂的关联条件查询，可以使用

$where = Comment::where('status',1)->where('content', 'like', '%think%');
$list = Article::hasWhere('comments', $where)->select();
注意：如果hasWhere需要和where同时使用的话，hasWhere必须在前面。

关联新增
$article = Article::find(1);
// 增加一个关联数据
$article->comments()->save(['content'=>'test']);
// 批量增加关联数据
$article->comments()->saveAll([
    ['content'=>'thinkphp'],
    ['content'=>'onethink'],
]);
相对关联
要在 Comment 模型定义相对应的关联，可使用 belongsTo 方法：

<?php
name app\model;

use think\Model;

class Comment extends Model 
{
    public function article()
    {
        return $this->belongsTo(Article::class);
    }
}
关联删除
在删除文章的同时删除下面的评论

$article = Article::with('comments')->find(1);
$article->together(['comments'])->delete();
远程一对多
远程一对多关联用于定义有跨表的一对多关系，例如：

每个城市有多个用户
每个用户有多个话题
城市和话题之间并无关联
关联定义
就可以直接通过远程一对多关联获取每个城市的多个话题，City模型定义如下：

<?php
namespace app\model;

use think\Model;

class City extends Model 
{
    public function topics()
    {
        return $this->hasManyThrough(Topic::class, User::class);
    }
}
远程一对多关联，需要同时存在Topic和User模型，当前模型和中间模型的关联关系可以是一对一或者一对多。

hasManyThrough方法的参数如下：

hasManyThrough('关联模型', '中间模型', '外键', '中间表关联键','当前模型主键','中间模型主键');
关联模型（必须）：关联模型类名
中间模型（必须）：中间模型类名
外键：默认的外键名规则是当前模型名+_id
中间表关联键：默认的中间表关联键名的规则是中间模型名+_id
当前模型主键：一般会自动获取也可以指定传入
中间模型主键：一般会自动获取也可以指定传入
关联查询
我们可以通过下面的方式获取关联数据

$city = City::find(1);
// 获取同城的所有话题
dump($city->topics);
// 也可以进行条件搜索
dump($city->topics()->where('topic.status',1)->select());
条件搜索的时候，需要带上模型名作为前缀

根据关联条件查询
如果需要根据关联条件来查询当前模型，可以使用

$list = City::hasWhere('topics', ['status' => 1])->select();
更复杂的查询条件可以使用

$where = Topic::where('status', 1)->where('title', 'like', '%think%');
$list = City::hasWhere('topics',$where)->select();
注意：如果hasWhere需要和where同时使用的话，hasWhere必须在前面。
远程一对一
远程一对一关联用于定义有跨表的一对一关系，例如：

每个用户有一个档案
每个档案有一个档案卡
用户和档案卡之间并无关联
关联定义
就可以直接通过远程一对一关联获取每个用户的档案卡，User模型定义如下：

<?php
namespace app\model;

use think\Model;

class User extends Model 
{
    public function card()
    {
        return $this->hasOneThrough(Card::class,Profile::class);
    }
}
远程一对一关联，需要同时存在Card和Profile模型。

hasOneThrough方法的参数如下：

hasOneThrough('关联模型', '中间模型', '外键', '中间表关联键','当前模型主键','中间模型主键');
关联模型（必须）：关联模型类名
中间模型（必须）：中间模型类名
外键：默认的外键名规则是当前模型名+_id
中间表关联键：默认的中间表关联键名的规则是中间模型名+_id
当前模型主键：一般会自动获取也可以指定传入
中间模型主键：一般会自动获取也可以指定传入
关联查询
我们可以通过下面的方式获取关联数据

$user = User::find(1);
// 获取用户的档案卡
dump($user->card);
多对多关联
关联定义
例如，我们的用户和角色就是一种多对多的关系，我们在User模型定义如下：

<?php
namespace app\model;

use think\Model;

class User extends Model 
{
    public function roles()
    {
        return $this->belongsToMany(Role::class, 'access');
    }
}
belongsToMany方法的参数如下：

belongsToMany('关联模型','中间表','外键','关联键');
关联模型（必须）：关联模型类名
中间表：默认规则是当前模型名+_+关联模型名 （可以指定模型名）
外键：中间表的当前模型外键，默认的外键名规则是关联模型名+_id
关联键：中间表的当前模型关联键名，默认规则是当前模型名+_id
中间表名无需添加表前缀，并支持定义中间表模型，例如：

    public function roles()
    {
        return $this->belongsToMany(Role::class, Access::class);
    }
中间表模型类必须继承think\model\Pivot，例如：

<?php
namespace app\model;

use think\model\Pivot;

class Access extends Pivot
{
    protected $autoWriteTimestamp = true;
}
中间表模型的基类Pivot默认关闭了时间戳自动写入，上面的中间表模型则开启了时间戳字段自动写入。

关联查询
我们可以通过下面的方式获取关联数据

$user = User::find(1);
// 获取用户的所有角色
$roles = $user->roles;
foreach ($roles as $role) {
	// 输出用户的角色名
	echo $role->name;
    // 获取中间表模型
    dump($role->pivot);
}
关联新增
$user = User::find(1);
// 给用户增加管理员权限 会自动写入角色表和中间表数据
$user->roles()->save(['name'=>'管理员']);
// 批量授权
$user->roles()->saveAll([
    ['name'=>'管理员'],
    ['name'=>'操作员'],
]);
只新增中间表数据（角色已经提前创建完成），可以使用

$user = User::find(1);
// 仅增加管理员权限（假设管理员的角色ID是1）
$user->roles()->save(1);
// 或者
$role = Role::find(1);
$user->roles()->save($role);
// 批量增加关联数据
$user->roles()->saveAll([1,2,3]);
单独更新中间表数据，可以使用：

$user = User::find(1);
// 增加关联的中间表数据
$user->roles()->attach(1);
// 传入中间表的额外属性
$user->roles()->attach(1,['remark'=>'test']);
// 删除中间表数据
$user->roles()->detach([1,2,3]);
attach方法的返回值是一个Pivot对象实例，如果是附加多个关联数据，则返回Pivot对象实例的数组。

相对关联
我们可以在Role模型中定义一个相对的关联关系，例如：

<?php
namespace app\model;

use think\Model;

class Role extends Model 
{
    public function users()
    {
        return $this->belongsToMany(User::class, Access::class);
    }
}
多态一对多
多态关联允许一个模型在单个关联定义方法中从属一个以上其它模型，例如用户可以评论书和文章，但评论表通常都是同一个数据表的设计。多态一对多关联关系，就是为了满足类似的使用场景而设计。

下面是关联表的数据表结构：

article
    id - integer
    title - string
    content - text

book
    id - integer
    title - string

comment
    id - integer
    content - text
    commentable_id - integer
    commentable_type - string
有两个需要注意的字段是 comment 表中的 commentable_id 和 commentable_type我们称之为多态字段。其中， commentable_id 用于存放书或者文章的 id（主键） ，而 commentable_type 用于存放所属模型的类型。通常的设计是多态字段有一个公共的前缀（例如这里用的commentable），当然，也支持设置完全不同的字段名（例如使用data_id和type）。

关联定义
接着，让我们来查看创建这种关联所需的模型定义：

文章模型：

<?php
namespace app\model;

use think\Model;

class Article extends Model
{
    /**
     * 获取所有针对文章的评论。
     */
    public function comments()
    {
        return $this->morphMany(Comment::class, 'commentable');
    }
}
morphMany方法的参数如下：

morphMany('关联模型','多态字段','多态类型');
关联模型（必须）：关联的模型类名

多态字段（可选）：支持两种方式定义 如果是字符串表示多态字段的前缀，多态字段使用 多态前缀_type和多态前缀_id，如果是数组，表示使用['多态类型字段名','多态ID字段名']，默认为当前的关联方法名作为字段前缀。

多态类型（可选）：当前模型对应的多态类型，默认为当前模型名，可以使用模型名（如Article）或者完整的命名空间模型名（如app\index\model\Article）。

书籍模型：

<?php
namespace app\model;

use think\Model;

class Book extends Model
{
    /**
     * 获取所有针对书籍的评论。
     */
    public function comments()
    {
        return $this->morphMany(Comment::class, 'commentable');
    }
}
书籍模型的设置方法同文章模型一致，区别在于多态类型不同，但由于多态类型默认会取当前模型名，因此不需要单独设置。

下面是评论模型的关联定义：

<?php
namespace app\model;

use think\Model;

class Comment extends Model
{
    /**
     * 获取评论对应的多态模型。
     */
    public function commentable()
    {
        return $this->morphTo();
    }
}
morphTo方法的参数如下：

morphTo('多态字段',['多态类型别名']);
多态字段（可选）：支持两种方式定义 如果是字符串表示多态字段的前缀，多态字段使用 多态前缀_type和多态前缀_id，如果是数组，表示使用['多态类型字段名','多态ID字段名']，默认为当前的关联方法名作为字段前缀
多态类型别名（可选）：数组方式定义

关联查询
一旦你的数据表及模型被定义，则可以通过模型来访问关联。例如，若要访问某篇文章的所有评论，则可以简单的使用 comments 动态属性：

$article = Article::find(1);

foreach ($article->comments as $comment) {
    dump($comment);
}
你也可以从多态模型的多态关联中，通过访问调用 morphTo 的方法名称来获取拥有者，也就是此例子中 Comment 模型的 commentable 方法。所以，我们可以使用动态属性来访问这个方法：

$comment = Comment::find(1);
$commentable = $comment->commentable;
Comment 模型的 commentable 关联会返回 Article 或 Book 模型的对象实例，这取决于评论所属模型的类型。

自定义多态关联的类型字段
默认情况下，ThinkPHP 会使用模型名作为多态表的类型区分，例如，Comment属于 Article 或者 Book , commentable_type 的默认值可以分别是 Article 或者 Book 。我们可以通过定义多态的时候传入参数来对数据库进行解耦。

    public function commentable()
    {
        return $this->morphTo('commentable',[
        	'book'	=>	'app\index\model\Book',
            'post'	=>	'app\admin\model\Article',
        ]);
    }
多态一对一
多态一对一相比多态一对多关联的区别是动态的一对一关联，举个例子说有一个个人和团队表，而无论个人还是团队都有一个头像需要保存但都会对应同一个头像表

member
    id - integer
    name - string
    
team
    id - integer
    name - string
    
avatar
    id - integer
    avatar - string
    imageable_id - integer
    imageable_type - string 
关联定义
会员模型：

<?php
namespace app\model;

use think\Model;

class Member extends Model
{
    /**
     * 获取用户的头像
     */
    public function avatar()
    {
        return $this->morphOne(Avatar::class, 'imageable');
    }
}
团队模型：

<?php
namespace app\model;

use think\Model;

class Team extends Model
{
    /**
     * 获取团队的头像
     */
    public function avatar()
    {
        return $this->morphOne(Avatar::class, 'imageable');
    }
}
morphOne方法的参数如下：

morphOne('关联模型','多态字段','多态类型');
关联模型（必须）：关联的模型类名。

多态字段（可选）：支持两种方式定义 如果是字符串表示多态字段的前缀，多态字段使用 多态前缀_type和多态前缀_id，如果是数组，表示使用['多态类型字段名','多态ID字段名']，默认为当前的关联方法名作为字段前缀。

多态类型（可选）：当前模型对应的多态类型，默认为当前模型名，可以使用模型名（如Member）或者完整的命名空间模型名（如app\index\model\Member）。

下面是头像模型的关联定义：

<?php
namespace app\model;

use think\Model;

class Avatar extends Model
{
    /**
     * 获取头像对应的多态模型。
     */
    public function imageable()
    {
        return $this->morphTo();
    }
}
理解了多态一对多关联后，多态一对一关联其实就很容易理解了，区别就是当前模型和动态关联的模型之间的关联属于一对一关系。

绑定属性到父模型（V2.0.40+）
可以在定义关联的时候使用bind方法绑定属性到父模型，例如：

<?php
namespace app\model;

use think\Model;

class Team extends Model
{
    /**
     * 获取团队的头像
     */
    public function avatar()
    {
        return $this->morphOne(Avatar::class, 'imageable')->bind(['nickname', 'email']);
    }
}
或者指定绑定属性别名

<?php
namespace app\model;

use think\Model;

class Team extends Model
{
    /**
     * 获取团队的头像
     */
    public function avatar()
    {
        return $this->morphOne(Avatar::class, 'imageable')->bind([
        		'email',
                'truename'	=> 'nickname',
            ]);
    }
}
然后使用关联预载入查询的时候，可以使用

$team = Team::with('avatar')->find(1);
// 直接输出Avatar关联模型的绑定属性
echo $team->email;
echo $team->truename;
绑定关联模型的属性支持读取器。
关联预载入
关联预载入
关联查询的预查询载入功能，主要解决了N+1次查询的问题，例如下面的查询如果有3个记录，会执行4次查询：

$list = User::select([1,2,3]);
foreach($list as $user){
    // 获取用户关联的profile模型数据
    dump($user->profile);
}
如果使用关联预查询功能，就可以变成2次查询（对于一对一关联来说，如果使用withJoin方式只有一次查询），有效提高性能。

$list = User::with(['profile'])->select([1,2,3]);
foreach($list as $user){
    // 获取用户关联的profile模型数据
    dump($user->profile);
}
支持预载入多个关联，例如：

$list = User::with(['profile', 'book'])->select([1,2,3]);
with方法只能调用一次，请不要多次调用，如果需要对多个关联模型预载入使用数组即可。

也可以支持嵌套预载入，例如：

$list = User::with(['profile.phone'])->select([1,2,3]);
foreach($list as $user){
    // 获取用户关联的phone模型
    dump($user->profile->phone);
}
支持使用数组方式定义嵌套预载入，例如下面的预载入要同时获取用户的Profile关联模型的Phone、Job和Img子关联模型数据：

$list = User::with(['profile'=>['phone','job','img']])->select([1,2,3]);
foreach($list as $user){
    // 获取用户关联
    dump($user->profile->phone);
    dump($user->profile->job);    
    dump($user->profile->img);    
}
如果要指定属性查询，可以使用：

$list = User::field('id,name')->with(['profile' => function($query){
	$query->field('user_id,email,phone');
}])->select([1,2,3]);

foreach($list as $user){
    // 获取用户关联的profile模型数据
    dump($user->profile);
}
记得指定属性的时候一定要包含关联键。

默认情况下，关联查询的数据是不包含软删除数据的，如果需要包含软删除数据，可以在关联定义的时候或预载入查询的闭包方法里面使用withTrashed()方法。

$users = User::with(['profile'	=> function(Query $query) {
	$query->withTrashed();
}])->select();
如果需要在关联查询的时候指定不需要的全局查询范围，可以使用withoutScope()方法。

$users = User::with(['profile'	=> function(Query $query) {
	$query->withoutScope(['age']);
}])->select();
如果是一对一关联，可以动态绑定属性到父模型（如果是多对多关联，则支持动态绑定中间表属性到父模型）。

$users = User::with(['profile'	=> function(Query $query) {
	$query->withBind(['name']);
}])->select();
对于一对多关联来说，如果需要设置返回的关联数据数量，使用withLimit方法（limit方法无效）。

Article::with(['comments' => function(Query $query) {
    $query->order('create_time', 'desc')->withLimit(3);
})->select();
关联预载入名称是关联方法名，支持传入方法名的小写和下划线定义方式，例如如果关联方法名是userProfile和userBook的话：

$list = User::with(['userProfile','userBook'])->select([1,2,3]);
和下面的方法都可以查询到关联数据：

$list = User::with(['user_profile','user_book'])->select([1,2,3]);
区别在于你获取关联数据的时候必须和传入的关联名称保持一致。

$user = User::with(['userProfile'])->find(1);
dump($user->userProfile);

$user = User::with(['user_profile'])->find(1);
dump($user->user_profile);
一对一关联预载入支持两种方式：JOIN方式（一次查询）和IN方式（两次查询，默认方式），如果要使用JOIN方式关联预载入，可以使用withJoin方法。

$list = User::withJoin(['profile' => function(Relation $query){
	$query->withField('truename,email');
}])->select([1,2,3]);
延迟预载入
有些情况下，需要根据查询出来的数据来决定是否需要使用关联预载入，当然关联查询本身就能解决这个问题，因为关联查询是惰性的，不过用预载入的理由也很明显，性能具有优势。

延迟预载入仅针对多个数据的查询，因为单个数据的查询用延迟预载入和关联惰性查询没有任何区别，所以不需要使用延迟预载入。

如果你的数据集查询返回的是数据集对象，可以使用调用数据集对象的load实现延迟预载入：

// 查询数据集
$list = User::select([1,2,3]);
// 延迟预载入
$list->load(['cards']);
foreach($list as $user){
    // 获取用户关联的card模型数据
    dump($user->cards);
}
关联预载入缓存
关联预载入可以支持查询缓存，例如：

$list = User::with(['profile'])->withCache(30)->select([1,2,3]);
表示对关联数据缓存30秒。

如果你有多个关联数据，也可以仅仅缓存部分关联

$list = User::with(['profile', 'book'])->withCache(['profile'],30)->select([1,2,3]);
对于延迟预载入查询的话，可以在第二个参数传入缓存参数。

// 查询数据集
$list = User::select([1,2,3]);
// 延迟预载入
$list->load(['cards'], 30);
复制
关联统计
关联统计
有些时候，并不需要获取关联数据，而只是希望获取关联数据的统计，这个时候可以使用withCount方法进行指定关联的统计。

$list = User::withCount('cards')->select([1,2,3]);
foreach($list as $user){
    // 获取用户关联的card关联统计
    echo $user->cards_count;
}
你必须给User模型定义一个名称是cards的关联方法。

关联统计功能会在模型的对象属性中自动添加一个以“关联方法名+_count”为名称的动态属性来保存相关的关联统计数据。

可以通过数组的方式同时查询多个统计字段。

$list = User::withCount(['cards', 'phone'])->select([1,2,3]);
foreach($list as $user){
    // 获取用户关联关联统计
    echo $user->cards_count;
    echo $user->phone_count;
}
支持给关联统计指定统计属性名，例如：

$list = User::withCount(['cards' => 'card_count'])->select([1,2,3]);
foreach($list as $user){
    // 获取用户关联的card关联统计
    echo $user->card_count;
}
关联统计暂不支持多态关联

如果需要对关联统计进行条件过滤，可以使用闭包方式。

$list = User::withCount(['cards' => function($query) {
    $query->where('status',1);
}])->select([1,2,3]);

foreach($list as $user){
    // 获取用户关联的card关联统计
    echo $user->cards_count;
}
使用闭包的方式，如果需要自定义统计字段名称，可以使用

$list = User::withCount(['cards' => function($query, &$alias) {
    $query->where('status',1);
    $alias = 'card_count';
}])->select([1,2,3]);

foreach($list as $user){
    // 获取用户关联的card关联统计
    echo $user->card_count;
}
和withCount类似的方法，还包括：

关联统计方法	描述
withSum	关联SUM统计
withMax	关联Max统计
withMin	关联Min统计
withAvg	关联Avg统计
除了withCount之外的统计方法需要在第二个字段传入统计字段名，用法如下：

$list = User::withSum('cards', 'total')->select([1,2,3]);

foreach($list as $user){
    // 获取用户关联的card关联余额统计
    echo $user->cards_sum;
}
同样，也可以指定统计字段名

$list = User::withSum(['cards' => 'card_total'], 'total')->select([1,2,3]);

foreach($list as $user){
    // 获取用户关联的card关联余额统计
    echo $user->card_total;
}
所有的关联统计方法可以多次调用，每次查询不同的关联统计数据。

$list = User::withSum('cards', 'total')
    ->withSum('score', 'score') 
    ->select([1,2,3]);

foreach($list as $user){
    // 获取用户关联的card关联余额统计
    echo $user->card_total;
}
关联输出
关联数据的输出也可以使用hidden、visible和append方法进行控制，下面举例说明。

隐藏关联属性
如果要隐藏关联模型的属性，可以使用

$list = User::with('profile')->select();
$list->hidden(['profile.email'])->toArray();
输出的结果中就不会包含Profile模型的email属性，如果需要隐藏多个属性可以使用

$list = User::with('profile')->select();
$list->hidden(['profile' => ['address', 'phone', 'email']])->toArray();
显示关联属性
同样，可以使用visible方法来仅仅显示指定的关联属性：

$list = User::with('profile')->select();
$list->visible(['profile'=>['address','phone','email']])->toArray();
追加关联属性
追加一个Profile模型的额外属性（非实际数据，可能是定义了获取器方法）

$list = User::with('profile')->select();
$list->append(['profile.status'])->toArray();
也可以追加一个额外关联对象的属性

$list = User::with('profile')->select();
$list->append(['Book.name'])->toArray();
复制
SQL监听
如果开启了SQL监听（trigger_sql）的话，就会记录SQL日志。

首先需要设置日志对象（必须遵循PSR-3日志规范）

Db::setLog($log);
则会调用日志对象的log方法自动记录SQL日志，获取日志请通过日志对象的相关方法进行。

如果你在ThinkPHP6.0+版本中使用的话，框架会自动设置日志对象和记录日志。

如果需要增加额外的SQL监听，可以使用

Db::listen(function($sql, $runtime, $master) {
    // 进行监听处理
});
监听方法支持三个参数，依次是执行的SQL语句，运行时间（秒），以及主从标记（如果没有开启分布式的话，该参数为null，否则为布尔值）。
缓存机制
查询缓存
对于使用了闭包查询的情况，因为闭包不支持序列化的原因，因此目前不支持查询缓存，需要自己对查询结果数据进行缓存。

对于一些实时性不高的应用，查询缓存可以有效提高查询性能，使用cache方法可以完成查询缓存。

cache可以用于select、find、value和column方法，以及其衍生方法，使用cache方法后，在缓存有效期之内不会再次进行数据库查询操作，而是直接获取缓存中的数据。

下面举例说明，例如，我们对find方法使用cache方法如下：

Db::table('user')->where('id',5)->cache(true)->find();
第一次查询结果会被缓存，第二次查询相同的数据的时候就会直接返回缓存中的内容，而不需要再次进行数据库查询操作。

默认情况下， 缓存有效期是由缓存对象的默认缓存配置参数决定的，但cache方法可以单独指定，例如：

Db::table('user')->cache(60)->find();
表示对查询结果的缓存有效期60秒。

缓存标识由系统自动生成，但可以手动指定缓存标识：

Db::table('user')->cache('key',60)->find();
指定查询缓存的标识可以使得查询缓存更有效率。

指定缓存标识的一个好处是可以在外部就可以通过缓存对象直接获取查询缓存的数据。

cache方法支持设置缓存标签，例如：

Db::table('user')->cache('key',60,'tagName')->find();
缓存自动更新
缓存自动更新是指一旦数据更新或者删除后会自动清理缓存（下次获取的时候会自动重新缓存）。

当你删除或者更新数据的时候，可以调用相同key的cache方法，会自动更新（清除）缓存，例如：

Db::table('user')->cache('user_data')->select([1,3,5]);
Db::table('user')->cache('user_data')->update(['id'=>1,'name'=>'thinkphp']);
Db::table('user')->cache('user_data')->select([1,3,5]);
最后查询的数据不会受第一条查询缓存的影响，确保查询和更新或者删除使用相同的缓存标识才能自动清除缓存。

如果使用主键进行查询和更新(或者删除）的话，无需指定缓存标识会自动更新缓存

Db::table('user')->cache(true)->find(1);
Db::table('user')->cache(true)->where('id', 1)->update(['name'=>'thinkphp']);
Db::table('user')->cache(true)->find(1);
字段缓存
字段缓存
由于字段检查和自动参数绑定需要，在每次查询数据表数据之前需要获取该表的字段信息，但可以支持字段缓存功能。

要开启字段缓存功能必须在数据库配置中设置：

// 开启字段缓存
'fields_cache'      => true,
// 字段缓存路径
'schema_cache_path' => 'path/to/cache',
开启后，会自动生成使用过的数据表字段缓存，如果你更改了数据表的字段及类型，需要清空字段缓存文件。字段缓存采用文件方式保存，路径由schema_cache_path配置参数设置。

如果是在ThinkPHP6.0+中使用，则可以使用指令直接生成（或更新）字段缓存

php think optimize:schema
如果你的模型类是各个应用独立的话，需要指定应用名生成字段缓存

php think optimize:schema index
也可以指定生成某个数据库的所有数据表字段缓存。

php think optimize:schema --db demo
每次执行指令都会重新生成数据表字段缓存文件，如果只是更改了数据表的某个字段或者增加了新的字段，重新部署上线的时候，支持单独更新某个数据表的缓存。

使用--table参数指定需要更新的数据表：

php think optimize:schema --table user

支持指定数据库名称

php think optimize:schema --table demo.user

生成字段缓存后，你会发现数据库的查询性能提升明显，尤其是在请求中操作大量数据表的情况下。
查询缓存
查询缓存
对于使用了闭包查询的情况，因为闭包不支持序列化的原因，因此目前不支持查询缓存，需要自己对查询结果数据进行缓存。

对于一些实时性不高的应用，查询缓存可以有效提高查询性能，使用cache方法可以完成查询缓存。

cache可以用于select、find、value和column方法，以及其衍生方法，使用cache方法后，在缓存有效期之内不会再次进行数据库查询操作，而是直接获取缓存中的数据。

下面举例说明，例如，我们对find方法使用cache方法如下：

Db::table('user')->where('id',5)->cache(true)->find();
第一次查询结果会被缓存，第二次查询相同的数据的时候就会直接返回缓存中的内容，而不需要再次进行数据库查询操作。

默认情况下， 缓存有效期是由缓存对象的默认缓存配置参数决定的，但cache方法可以单独指定，例如：

Db::table('user')->cache(60)->find();
表示对查询结果的缓存有效期60秒。

缓存标识由系统自动生成，但可以手动指定缓存标识：

Db::table('user')->cache('key',60)->find();
指定查询缓存的标识可以使得查询缓存更有效率。

指定缓存标识的一个好处是可以在外部就可以通过缓存对象直接获取查询缓存的数据。

cache方法支持设置缓存标签，例如：

Db::table('user')->cache('key',60,'tagName')->find();
缓存自动更新
缓存自动更新是指一旦数据更新或者删除后会自动清理缓存（下次获取的时候会自动重新缓存）。

当你删除或者更新数据的时候，可以调用相同key的cache方法，会自动更新（清除）缓存，例如：

Db::table('user')->cache('user_data')->select([1,3,5]);
Db::table('user')->cache('user_data')->update(['id'=>1,'name'=>'thinkphp']);
Db::table('user')->cache('user_data')->select([1,3,5]);
最后查询的数据不会受第一条查询缓存的影响，确保查询和更新或者删除使用相同的缓存标识才能自动清除缓存。

如果使用主键进行查询和更新(或者删除）的话，无需指定缓存标识会自动更新缓存

Db::table('user')->cache(true)->find(1);
Db::table('user')->cache(true)->where('id', 1)->update(['name'=>'thinkphp']);
Db::table('user')->cache(true)->find(1);
复制
自定义查询类
自定义查询类
默认情况下，默认使用的查询类是核心内置的think\db\Query类，如果你需要自己扩展额外的查询方法，可以自定义查询类，例如：

<?php

namespace app\db;

use think\db\Query;

class MyQuery extends  Query
{
   
    public function top($num)
    {
    	return $this->limit($num)->select();
    }
}
然后在数据库配置文件中设置query属性如下

'connections'    =>    [
    'mysql'    =>    [
        // 数据库类型
        'type'        => 'mysql',
        // 服务器地址
        'hostname'    => '127.0.0.1',
        // 数据库名
        'database'    => 'thinkphp',
        // 数据库用户名
        'username'    => 'root',
        // 数据库密码
        'password'    => '',
        // 数据库连接端口
        'hostport'    => '',
        // 数据库连接参数
        'params'      => [],
        // 数据库编码默认采用utf8
        'charset'     => 'utf8',
        // 数据库表前缀
        'prefix'      => 'think_',
        // 自定义查询类
    	'query'       => '\app\db\MyQuery',
    ],
],
设置后，在Db类或者模型里就可以使用top方法查询

User::where('id desc')->top(10);
复制
自定义数据库驱动
数据库驱动
如果你需要自定义数据库驱动，需要自定义实现数据库连接类（Connection）和解析类（Builder）。连接类需要继承think\db\Connection，如果是基于PDO支持的数据库类型则可以直接继承think\db\PDOConnection。

解析类一般继承think\db\Builder，对于特殊的驱动，可能还需要实现查询类（或者继承think\db\BaseQuery）。

具体数据库驱动的实现，要根据你的自定义Connection类来决定。可以参考内置的oracle驱动和mongo驱动的实现。

一旦自定义了数据库驱动，例如你自定义实现了think\db\Db2的话，你需要在数据库配置文件中配置type参数：

'type'  =>   'think\db\Db2',
