/*
 Navicat Premium Dump SQL

 Source Server         : localhost80
 Source Server Type    : MySQL
 Source Server Version : 80045 (8.0.45)
 Source Host           : localhost:3306
 Source Schema         : b8aiadmin

 Target Server Type    : MySQL
 Target Server Version : 80045 (8.0.45)
 File Encoding         : 65001

 Date: 02/06/2026 03:12:18
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for sa_article
-- ----------------------------
DROP TABLE IF EXISTS `sa_article`;
CREATE TABLE `sa_article` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '编号',
  `category_id` int NOT NULL COMMENT '分类id',
  `title` varchar(255) NOT NULL DEFAULT '' COMMENT '文章标题',
  `author` varchar(255) DEFAULT NULL COMMENT '文章作者',
  `image` varchar(1000) DEFAULT '' COMMENT '文章图片',
  `describe` varchar(1000) NOT NULL COMMENT '文章简介',
  `content` text NOT NULL COMMENT '文章内容',
  `views` int DEFAULT '0' COMMENT '浏览次数',
  `sort` int unsigned DEFAULT '100' COMMENT '排序',
  `status` tinyint unsigned DEFAULT '1' COMMENT '状态',
  `is_link` tinyint(1) DEFAULT '2' COMMENT '是否外链',
  `link_url` varchar(255) DEFAULT NULL COMMENT '链接地址',
  `is_hot` tinyint unsigned DEFAULT '2' COMMENT '是否热门',
  `created_by` int DEFAULT NULL COMMENT '创建者',
  `updated_by` int DEFAULT NULL COMMENT '更新者',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_category_id` (`category_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='文章表';

-- ----------------------------
-- Records of sa_article
-- ----------------------------
BEGIN;
INSERT INTO `sa_article` (`id`, `category_id`, `title`, `author`, `image`, `describe`, `content`, `views`, `sort`, `status`, `is_link`, `link_url`, `is_hot`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1, 1, '科技为农业强国建设插上腾飞之翼', '新华网', 'https://www.news.cn/tech/20251203/51066a5dc41545fa849d49423770ad70/2025120351066a5dc41545fa849d49423770ad70_202512037a03214ec26c4f029d6e1599d07c3779.png', '“十四五”规划提出，完善农业科技创新体系，创新农技推广服务方式，建设智慧农业。5年来，在科技创新的强劲支撑下，14亿人的饭碗端得更牢、农业现代化水平显著提升、产业新动能持续增强，农业强国建设迈上新台阶。', '<p style=\"text-align: justify;\"> &nbsp; &nbsp; &nbsp; &nbsp;“平均亩产1209.1公斤，这标志着全国首个两百万亩玉米‘吨粮田’成功创建。”金秋时节，新疆伊犁哈萨克自治州传来喜讯。这一纪录的诞生，离不开中国农业科学院研发的“玉米密植高产精准调控技术”支撑。依托该技术，位于伊犁的200余万亩玉米高产田亩保苗株数从传统的不足5000株提升到7000—8000株，玉米收获穗数大幅提升。</p><p style=\"text-align: justify;\">　　这只是我国科技强农、粮食增产增收的一个缩影。“十四五”以来，我国粮食总产量始终保持在1.3万亿斤以上。2024年粮食总产量更是首次突破1.4万亿斤，比2020年增产740亿斤。</p><p style=\"text-align: justify;\">　　习近平总书记强调，发展现代农业，建设农业强国，必须依靠科技进步，让科技为农业现代化插上腾飞的翅膀。</p><p style=\"text-align: justify;\">　　“十四五”规划提出，完善农业科技创新体系，创新农技推广服务方式，建设智慧农业。5年来，在科技创新的强劲支撑下，14亿人的饭碗端得更牢、农业现代化水平显著提升、产业新动能持续增强，农业强国建设迈上新台阶。</p><p style=\"text-align: justify;\">　　科技铸“芯”，夯实大国粮仓之基</p><p style=\"text-align: justify;\">　　国以农为本，农以种为先，种子被誉为农业的“芯片”。前不久，四川省富顺县水稻百亩超高产攻关片进行实割实测，再生稻亩产达到494.81公斤，加上此前测产中稻亩产807.13公斤，合计亩产突破1300公斤。取得这一成绩的背后，是“甬优4949”等高产突破性品种的选育和“中稻+再生稻”生产模式的推广。</p><p style=\"text-align: justify;\">　　水稻是我国第一大口粮。“十四五”时期全国多地选育出一批水稻突破性品种：安徽农业大学水稻栽培团队推广自育水稻品种，帮助当地农户水稻亩产增至800公斤；湖南杂交水稻研究中心选育出“西子3号”，推动解决部分受重金属污染地区“镉大米”问题；国家耐盐碱水稻技术创新中心培育出“箐两优3261”，填补了我国华南滨海盐碱区暂无强耐盐、多抗、优质杂交稻品种的空白……</p><p style=\"text-align: justify;\">　　习近平总书记指出，中国人的饭碗要牢牢端在自己手中，就必须把种子牢牢攥在自己手里。</p><p style=\"text-align: justify;\">　　作为我国另一大口粮，小麦育种的创新步伐也不断提速。2025年，西北农林科技大学一次性通过国家审定12个新品种，覆盖半冬性、冬性、春性类型，在抗倒伏等方面实现全面突破。这些为不同生态区“量身定制”的品种，在丰富我国小麦品种的同时，也大幅提升了小麦产能潜力。截至目前，西农小麦系列品种累计推广面积已达18亿亩，为保障国家粮食安全提供了坚实的种源支撑。</p><p style=\"text-align: justify;\">　　“十四五”以来，我国深入实施种业振兴行动，育成了一批生产急需的重大品种，选育出优质高产水稻、节水抗病小麦、机收籽粒玉米、高油高产大豆等急需品种，农作物自主选育品种面积占比超过了95%，做到了“中国粮”主要用“中国种”。</p><p style=\"text-align: justify;\">　　“去年全国粮食亩产394.7公斤，比‘十三五’末提高了12.5公斤，单产提升对我国粮食产量增长的贡献超过60%，有些年份会超过80%。”农业农村部党组书记、部长韩俊表示，“十四五”以来，农业农村部深入实施国家粮食安全战略，“以我为主、立足国内、确保产能、适度进口、科技支撑”，坚持产量产能、生产生态、增产增收一起抓，强化藏粮于地、藏粮于技，全方位夯实粮食安全根基。</p><p style=\"text-align: justify;\">　　智慧提“效”，驱动耕作方式变革</p><p style=\"text-align: justify;\">　　气象墒情传感器、智能虫情测报站等设备如同“千里眼”，与空中无人机巡航、地面机器狗巡检形成立体监测网络。这是日前科技日报记者在北京市昌平区的天汇园果园见到的一幕。</p><p style=\"text-align: justify;\">　　“目前，该果园环境和土壤墒情覆盖10余项指标，虫情识别准确率达90%，种植生产信息化率超过95%，同时土壤成分快检技术能在30分钟内完成土壤成分‘体检’，辅助实现果园虫情和灾情等早预警、早干预。”北京市智慧农业创新团队岗位专家吴建伟介绍，该果园管理从“经验驱动”转向“数据驱动”，为果树生长提供了全天候守护。</p><p style=\"text-align: justify;\">　　在四川省成都市新都区稻菜现代农业园区，当地自主研发的农业巡检机器人已代替人工开展巡检工作；在浙江省衢州市龙游县田间地头，一架植保无人机3小时就能完成300亩农田的喷药流程，相当于40多个人整整一天的工作量……</p><p style=\"text-align: justify;\">　　“十四五”以来，类似的农业新场景新模式不断涌现，现代农业设施装备持续普及应用。我国先后支持建设国家智慧农业创新应用项目116个，深入开展国产化智慧农业技术的中试熟化、推广应用，探索形成了一批信息技术与农机农艺相融合的节本增产增效技术模式。</p><p style=\"text-align: justify;\">　　习近平总书记指出，农业科技创新要着力提升创新体系整体效能，农业科技工作要突出应用导向，把论文写在大地上。</p><p style=\"text-align: justify;\">　　5年来，我国农业科技创新体系整体效能显著提升。我国充分利用物联网、大数据、人工智能等现代信息技术发展智慧农业，并研制出一批先进智能适用的农机装备。</p><p style=\"text-align: justify;\">　　“随着智能农机加快推广，全国安装北斗终端的农机约200万台，植保无人机年作业面积超过4.1亿亩。人工智能、农业机器人等新技术与农业生产经营加速融合，精准播种、变量施肥、智慧灌溉、精准饲喂、环境控制等逐渐普及。”农业农村部市场与信息化司司长雷刘功介绍。</p><p style=\"text-align: justify;\">　　这些前沿技术的落地应用，正是农业科技现代化推动农业现代化的生动实践。“十四五”以来，我国坚持用现代设施装备武装农业，用现代科学技术服务农业，推动农业现代化水平不断提高。2024年底，农业科技进步贡献率已经达到了63.2%，农作物耕种收综合机械化率超过75%。</p><p style=\"text-align: justify;\">　　创新延“链”，拓宽食物供给版图</p><p style=\"text-align: justify;\">　　近日，蒙牛集团携多款产品参加第八届中国国际进口博览会，展示其发展新质生产力的最新成果。“我们打造的全球液态奶行业首座‘灯塔工厂’，已成为全球乳业最高人效比的新标杆，是中国乳业抢占全球智能制造新高地的生动写照。”中粮集团副总经理、蒙牛乳业董事长庆立军介绍。这座“灯塔工厂”通过实施30多项第四次工业革命技术，实现了“百人百亿”的极致人效比——100名员工，年产能达百万吨，创造产值百亿元。</p><p style=\"text-align: justify;\">　　今天，科研创新已成为发展现代化海洋牧场的强大引擎。南方海洋实验室研发“珠海琴”等多功能融合的新型组合式结构加强型养殖平台，为海洋养殖带来新变革；珠海市海洋集团形成海工型养殖装备设计、建造、施工和运维等全产业链条，成功研发“格盛一号”养殖平台，订单水体总量相当于新开拓28.25万亩耕地。</p><p style=\"text-align: justify;\">　　习近平总书记指出，要树立大农业观、大食物观，农林牧渔并举，构建多元化食物供给体系。</p><p style=\"text-align: justify;\">　　“十四五”以来，我国突出科技支撑，强化要素保障，努力向森林要食物，向草原要食物，向江河湖海要食物，向设施农业要食物，向植物动物微生物要热量、要蛋白，多元化食物供给体系加快构建。</p><p style=\"text-align: justify;\">　　一组数据表明，农业科技创新正通过看得见的方式，让老百姓的餐桌品类变得愈发丰富——2024年，我国肉蛋奶等畜产品总量达到1.75亿吨，比2020年增加2778万吨，增长18.8%；水产品总产量达到7358万吨，比2020年增长12.3%，水产品总产量持续36年居全球第一。</p><p style=\"text-align: justify;\">　　党的二十届四中全会审议通过的《中共中央关于制定国民经济和社会发展第十五个五年规划的建议》提出，“统筹发展科技农业、绿色农业、质量农业、品牌农业，把农业建成现代化大产业”。科技创新能够催生新产业、新模式、新动能，是发展新质生产力的核心要素。韩俊表示，加快建设农业强国，必须清醒认识到农业科技国际竞争新形势，把农业科技创新放在更加突出的位置，紧盯世界农业科技前沿，加快突破农业关键核心技术，努力抢占农业科技创新制高点，塑造农业农村发展新动能新优势，培育壮大农业新质生产力。</p>', 5, 100, 1, 2, '', 2, 1, 1, '2024-06-02 22:55:25', '2026-01-10 11:13:25', NULL);
INSERT INTO `sa_article` (`id`, `category_id`, `title`, `author`, `image`, `describe`, `content`, `views`, `sort`, `status`, `is_link`, `link_url`, `is_hot`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (2, 1, '商业航天稳步快跑 “太空旅游”渐行渐近', '新华网', 'https://www.news.cn/tech/20251124/c7cb9d4e405c4c82b78a8f861889cb22/20251124c7cb9d4e405c4c82b78a8f861889cb22_20251124044f95bbab864da2b0c30861aa41279b.png', '业界普遍认为，以可复用火箭为代表的核心技术突破是商业航天提速的关键支撑。据统计，2025年底至2026年初，我国可复用火箭技术将进入密集首飞期，包括蓝箭航天“朱雀三号”、中科宇航“力箭二号”、星际荣耀“双曲线三号”和星河动力“智神星一号”在内的多款可复用火箭将迎来首飞。', '<p style=\"text-align: justify;\"> &nbsp; &nbsp; &nbsp; &nbsp;可搭载7名乘客穿越卡门线，体验约4分钟失重体验……记者从11月22日在京开幕的第四届中国空间科学大会上了解到我国太空旅游的最新进展。与会专家学者认为，随着产业链条不断完善、核心技术持续突破，我国商业航天已迈入稳步快跑的发展新阶段，曾经遥不可及的“太空旅游”正加速走进现实。</p><p style=\"text-align: justify;\">  记者在第四届中国空间科学大会同期举行的“航天新技术、新成果展”上看到，我国首型面向太空旅游的可重复使用飞行器力鸿二号的模型吸引了众多参观者。中科宇航展台工作人员告诉记者，力鸿二号将采用“箭船分离”的方式将乘客送上太空：飞到既定高度之后，载人舱与火箭分离，继续飞越100公里的卡门线，开始约4分钟的失重段，之后返回地面，以伞降的方式着陆，火箭也将垂直着陆回收。“我们的目标是让力鸿二号可重复使用超30次，这样就能把飞行成本降下来，让更多的人体验太空旅游。”</p><p style=\"text-align: justify;\">  我国商业航天的快速发展让太空旅游渐行渐近。业界普遍认为，以可复用火箭为代表的核心技术突破是商业航天提速的关键支撑。据统计，2025年底至2026年初，我国可复用火箭技术将进入密集首飞期，包括蓝箭航天“朱雀三号”、中科宇航“力箭二号”、星际荣耀“双曲线三号”和星河动力“智神星一号”在内的多款可复用火箭将迎来首飞。</p><p style=\"text-align: justify;\">  不仅火箭研制加速突破，卫星应用也在不断拓展。此次展会上，微纳星空等卫星企业也带来了最新的研发成果。微纳星空品牌总监刘晓光介绍，即将发射的“全天候卫士”MN200S-2（01B）星是公司自主研制的商业X波段相控阵雷达成像领域的技术标杆型卫星，可广泛应用于应急救灾、海洋维权、国土安全、生态监测、智慧城市建设等场景，并可实现多星高密度堆叠发射，为后续卫星规模化组网编队提供关键技术验证与工程实践依据。“随着国家低轨卫星互联网的能力建设牵引，微纳星空已经开启批量化、低成本的卫星制造。”</p><p style=\"text-align: justify;\">  业界认为，目前我国已形成覆盖火箭研制、卫星制造、发射服务、地面应用的完整商业航天产业链，产业集群效应逐步显现。在北京，“南箭北星”的产业格局已显露雏形：亦庄新城正在打造全国首个商业航天共性科研生产基地——火箭大街，海淀区作为“北星”的核心承载区，已集聚涵盖商业卫星制造、测运控、运营及数据应用的近200家相关企业。“在此基础上，海淀正全力推进卫星小镇‘两区一平台’的建设：先导区目前已有40余家商业航天企业聚集；紧邻航天城的卫星小镇核心区54万平方米空间预计2026年6月竣备，将重点引入卫星上下游企业；同时，卫星小镇拟建公共服务平台，提供卫星整星及组部件的力学、热真空、抗辐射等多种测试服务。”卫星小镇核心区对接人段叶叶介绍。</p><p style=\"text-align: justify;\">  “我国发展商业航天的优势是人多、力量大、竞争强，技术和产品能够快速迭代，紧跟国际趋势。”中国科学院微小卫星创新研究院副院长张永合在接受记者专访时表示，但目前我国商业航天企业和人才大多集中在制造领域，“还需要更多能创造任务的人，有非常前沿的想法，有改变当前航天模式的颠覆性路径。”</p><p style=\"text-align: justify;\">  张永合认为，商业航天关键是要创造需求，“比如太空旅游就是商业航天创造的需求，将人们日常生活中的旅游延伸到太空中去，在产业上就属于增量。”未来，低空经济、空间互联网等也将打开想象空间。“有了坚实的技术底座，新的产业形态就会自然而然生长出来。”</p><p style=\"text-align: justify;\">  不过，业内专家也指出，我国商业航天发展仍面临体制机制创新不足、部分核心技术有待突破等挑战。从政策层面来看，近年来国家持续加大对商业航天的支持力度，相关扶持政策和行业规范正在逐步完善，旨在优化市场环境、加大核心技术研发支持，为商业航天高质量发展营造良好生态，推动太空旅游等新业态逐步走向成熟。</p><p style=\"text-align: justify;\">  业内普遍认为，商业航天已成为航天强国建设的重要增长点。从运载火箭重复使用技术突破到卫星应用场景拓展，随着技术持续成熟、产业链不断完善和政策环境优化，未来“上太空”有望从专业探索逐步走向大众体验，中国商业航天也将在全球太空经济格局中占据重要地位。</p><p><br></p>', 1, 100, 1, 2, '', 2, 1, 1, '2024-06-02 22:56:47', '2026-01-10 11:13:47', NULL);
INSERT INTO `sa_article` (`id`, `category_id`, `title`, `author`, `image`, `describe`, `content`, `views`, `sort`, `status`, `is_link`, `link_url`, `is_hot`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (3, 2, '以数字经济为引擎加快推进中国式现代化', '新华网', 'https://www.news.cn/tech/20251023/0cb8f0bcb7874992b8d431abdd7331a9/202510230cb8f0bcb7874992b8d431abdd7331a9_2025102332abb363b12744eb9f725ce395f16e4a.png', 'The Athletic报道，阿森纳理疗师乔丹-里斯即将加盟曼联，成为红魔的首席理疗师。曼联首席理疗师罗宾-萨德勒已于今年一月离开俱乐部', '<p style=\"text-align: justify;\"> &nbsp; &nbsp; &nbsp; &nbsp;随着中国式现代化不断向前推进，中国迎来了数字经济发展的新机遇。在数字经济快速发展的背景下，中国式现代化的内涵得以拓展，现代化动力得以重塑，现代化新动能得以培育，现代化新优势得以形成。数字技术创新、实体经济与数字经济融合、产业数字化、数字产业化成为推进中国式现代化的重要驱动力量。</p><p style=\"text-align: justify;\">  在数字经济推动下，现代化由工业经济时代的现代化向数字经济时代的现代化转变，在这一大背景下需要在理论上研究数字经济赋能中国式现代化的逻辑和机制，需要深入探讨中国式现代化如何紧紧抓住数字经济发展带来的新机遇，以数字化的知识和信息作为关键生产要素，以数字技术为核心驱动力，在数据要素和数字技术的双轮驱动下推动中国式现代化走上新征程。</p><p style=\"text-align: justify;\">  南京大学数字经济与管理学院任保平教授的专著《数字经济赋能中国式现代化》于2025年在江苏人民出版社出版，全书共17章，35.8万字。该书立足世界范围内数字化浪潮下的经济现代化背景，从理论与实践两个方面研究了数字经济发展对中国式现代化的赋能作用。</p><p style=\"text-align: justify;\">  在理论层面，该书研究了数字经济发展对中国式现代化的影响、数字经济与中国式现代化的有机衔接，数字经济背景下中国式现代化目标的重塑、数字经济与中国式现代化深度融合的逻辑机制，数字经济背景下中国式现代化的延伸和拓展。在实践层面，从中国式现代化的不同方面具体研究了数字经济的赋能作用，具体包括数字经济赋能中国式新型工业化、新型城镇化、科技现代化、农业农村现代化、产业现代化和科技现代化。</p><p style=\"text-align: justify;\">  该书的核心观点主要有以下方面。一是，中国式现代化战略在数字化转型背景下发生的一系列拓展。促进工业化与信息化的融合发展，以数字化带动工业化发展，加大数字技术研发力度，大力发展数字产业。以数字化带动农业现代化，补足中国式现代化短板。协同匹配数字经济时代的创新供求，提升产业技术创新能力。促进企业数字化转型，引领数字经济发展。协调产业数字化与数字产业化，推进产业基础现代化。加快新型基础设施建设，提升基础设施支撑能力。构建数字平台体系，打造现代化经济新形态。</p><p style=\"text-align: justify;\">  二是，以数字经济发展培育中国式现代化新优势。针对数字经济带来的现代化新变化，研究了数字经济对中国式现代化的引擎作用，认为目前中国式现代化正处于数字经济蓬勃发展带来无数新机遇的时代，我们要抓住数字经济发展带来的新机遇，以数字经济推动中国式现代化的新发展。</p><p style=\"text-align: justify;\">  三是，阐释数字经济赋能中国式现代化的逻辑。在理论上深刻阐释数字经济如何成为中国式现代化的新引擎，数字经济作为新引擎对中国式现代化赋能的驱动机制和路径，论证数字经济发展赋能中国式现代化在目标、路径和战略上的延伸和拓展，为数字经济赋能中国式现代化提供了一个理论框架。</p><p style=\"text-align: justify;\">  四是，研究数字经济全面赋能中国式现代化的机制。中国式经济现代化涉及多方面内容，包括科技现代化、工业现代化、农业现代化、服务业现代化、产业链现代化、城市现代化、区域现代化、城市现代化、生态现代化、企业现代化、人的现代化和治理现代化，数字经济应该从上述方面赋能中国式现代化。</p><p style=\"text-align: justify;\">  五是，提出了以数字经济培育中国式现代化新优势的路径。数字经济培育中国式现代化的新优势包括需求端的动力新优势、供给端的效率新优势等。需要从数字化转型的创新能力、基础设施的供给能力、数字化转型的战略支撑能力，数字化转型的保障能力等方面研究数字经济发展培育中国式现代化新优势的实现路径。而且，需要从效率变革机制、动力变革机制和质量变革机制等方面研究数字经济赋能中国式现代化新优势培育的机制，从数字产业化、产业数字化、产学研协同创新、劳动力质量和相关配套制度等方面实现数字经济培育中国式现代化的新优势，全面展示数字经济赋能中国式现代化中的应用场景。</p>', 2, 100, 1, 2, '', 2, 1, 1, '2024-06-02 22:58:41', '2026-01-10 11:13:01', NULL);
INSERT INTO `sa_article` (`id`, `category_id`, `title`, `author`, `image`, `describe`, `content`, `views`, `sort`, `status`, `is_link`, `link_url`, `is_hot`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (4, 2, '2025腾讯全球数字生态大会在深圳举行', '新华网', 'https://www.news.cn/tech/20250918/a8a0f6e1a6d740188db7752e247518bb/20250918a8a0f6e1a6d740188db7752e247518bb_202509184f78f2904fa2456db9537d878cb89166.jpg', '5月26日晚上18：00，中超第14轮，深圳新鹏城主场迎战上海申花，上半场马莱莱补射斩获赛季第6球，半场战罢，申花暂1-0新鹏城', '<p><br></p><div data-w-e-type=\"video\" data-w-e-is-void>\n<video poster=\"\" controls=\"true\" width=\"auto\" height=\"auto\"><source src=\"https://vodpub6.v.news.cn/yqfbzx-original/20250918/20250918a8a0f6e1a6d740188db7752e247518bb_XxjfceC000090_20250917_CBVFN0A001.mp4\" type=\"video/mp4\"/></video>\n</div><p><span style=\"color: rgb(0, 0, 0);\"> &nbsp; &nbsp; &nbsp; &nbsp;9月16日，2025腾讯全球数字生态大会在深圳举行，会上公布多项AI技术和产品最新进展，并宣布全面开放腾讯AI落地能力及优势场景，助力“好用的AI”在千行百业中加速落地。</span></p><p><br></p>', 3, 100, 1, 2, '', 2, 1, 1, '2024-06-02 22:59:41', '2026-01-10 13:42:34', NULL);
INSERT INTO `sa_article` (`id`, `category_id`, `title`, `author`, `image`, `describe`, `content`, `views`, `sort`, `status`, `is_link`, `link_url`, `is_hot`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (5, 3, '秀我中国丨中国小机器人“勇闯”美国CES', '新华网', 'https://www.news.cn/tech/20260109/b2c43e2b0d1e43a98840c33e37fbbc73/20260109896bd0b56c18435987243f0f5dc01d67_202601099d0953f9999949a9b55e9d212d7bf773.jpg', '2026年美国拉斯维加斯消费电子展（CES）6日至9日举行，首次亮相海外展会的中国小机器人“启元Q1”刚一登场就成为焦点，凭借其出色表现“圈粉”海外。', '<p><br></p><div data-w-e-type=\"video\" data-w-e-is-void>\n<video poster=\"https://vodpub6.v.news.cn/yqfbzx-original/20260109/image/2ff2c0d5-4060-400d-8640-b41a0da5af1f.jpg\" controls=\"true\" width=\"360\" height=\"640\"><source src=\"https://vodpub6.v.news.cn/yqfbzx-original/20260109/20260109896bd0b56c18435987243f0f5dc01d67_XxjfceC000165_20260109_CBVFN0A001.mp4\" type=\"video/mp4\"/></video>\n</div><p style=\"text-align: left;\"><span style=\"color: rgb(0, 0, 0);\"> &nbsp; &nbsp; &nbsp; &nbsp;2026年美国拉斯维加斯消费电子展（CES）6日至9日举行，首次亮相海外展会的中国小机器人“启元Q1”刚一登场就成为焦点，凭借其出色表现“圈粉”海外。</span></p>', 3, 100, 1, 2, '', 2, 1, 1, '2024-06-02 23:01:17', '2026-01-10 13:42:24', NULL);
INSERT INTO `sa_article` (`id`, `category_id`, `title`, `author`, `image`, `describe`, `content`, `views`, `sort`, `status`, `is_link`, `link_url`, `is_hot`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (6, 3, 'AI助力药物虚拟筛选提速百万倍 开启后AlphaFold时代创新药', '新华网', 'https://www.news.cn/tech/20260109/2e0f65d6733a4e2588a97dfe96593a09/202601092e0f65d6733a4e2588a97dfe96593a09_202601090012b088f5604e22a77ae70f8656f466.jpg', '团队与清华大学闫创业教授团队合作，在去甲肾上腺素转运体（NET）的临床相关靶点上开展了系列生物实验验证。', '<p><span style=\"color: rgb(0, 0, 0);\"> &nbsp; &nbsp; &nbsp; &nbsp;1月9日，清华大学智能产业研究院（AIR）联合清华大学生命学院、清华大学化学系在《科学》杂志发表论文《深度对比学习实现基因组级别药物虚拟筛选》。该论文研发了一个AI驱动的超高通量药物虚拟筛选平台DrugCLIP, 筛选速度对比传统方法实现百万倍提升，同时在预测准确率上也取得显著突破。依托该平台，团队打通了从AlphaFold结构预测到药物发现的关键通道，首次完成了覆盖人类基因组规模的药物虚拟筛选，为后AlphaFold时代的创新药物发现带来新可能性。</span></p><p><img src=\"https://www.news.cn/tech/20260109/2e0f65d6733a4e2588a97dfe96593a09/202601092e0f65d6733a4e2588a97dfe96593a09_2026010932fb993ce4734583aa3e4e861e536cff.png\" alt=\"\" data-href=\"\" style=\"\"/></p><p style=\"text-align: justify;\"> &nbsp; &nbsp;长期以来，药物研发面临“高风险、高投入、低成功率”的难题，在靶点发现与先导化合物筛选阶段，受限于传统工具的计算能力，绝大多数潜在靶点和化合物仍未被充分探索。如何在广阔的生物与化学空间中精准高效地发现活性化合物，是当前创新药物研发面临的核心挑战。</p><p style=\"text-align: justify;\">  据了解，为突破虚拟筛选规模瓶颈，DrugCLIP创新性地构建了蛋白口袋与小分子的“向量化结合空间”，将传统基于物理对接的筛选流程转化为高效的向量检索问题。该模型结合对比学习、3D结构预训练与多模态编码技术，能在三维结构层面精准建模蛋白-配体间的相互作用。训练后的高潜力分子将自然聚集于目标蛋白口袋的向量邻域，能够有效支撑快速的大规模虚拟筛选。依托这一机制，DrugCLIP在128核CPU+8张GPU的计算节点上，能实现毫秒级打分与万亿级日吞吐能力，筛选100万个候选分子仅需0.02秒，日处理能力达31万亿次，对比传统方法实现了百万倍提升。</p><p style=\"text-align: justify;\"><img src=\"https://www.news.cn/tech/20260109/2e0f65d6733a4e2588a97dfe96593a09/202601092e0f65d6733a4e2588a97dfe96593a09_2026010902fd55e1493f4741a2f10b4480ee398e.png\" alt=\"\" data-href=\"\" style=\"\"></p><p style=\"text-align: justify;\"> &nbsp; &nbsp;团队与清华大学闫创业教授团队合作，在去甲肾上腺素转运体（NET）的临床相关靶点上开展了系列生物实验验证。团队使用DrugCLIP模型从160万个候选分子中筛选出约100个高评分分子，同位素配体转运实验检测显示，其中15%为有效抑制剂，其中12个分子结合能力优于现有抗抑郁药物安非他酮。相关复合物结构已通过冷冻电镜解析，进一步验证了DrugCLIP筛选结果的生物学可信度。</p><p style=\"text-align: justify;\">  值得关注的是，DrugCLIP支持对AlphaFold预测的蛋白结构和apo（无配体）状态下的蛋白口袋进行筛选，扩大了其在真实药物发现场景中的适用性。团队和清华大学刘磊教授团队合作，针对E3泛素连接酶TRIP12（thyroid hormone receptor interactor 12）进行了虚拟筛选与实验验证。过往研究发现，TRIP12是多种肿瘤、帕金森综合征的潜在靶点，但是TRIP12缺少已知的小分子配体和复合物结构。团队使用DrugCLIP模型，从160万个候选分子中高通量筛选出约50个高评分分子，SPR实验证实，其中10个分子与TRIP12有结合能力，两个亲和力较高的分子也对TRIP12的泛素连接酶活性有一定的抑制活性。</p><p style=\"text-align: justify;\">  此外，依托DrugCLIP，团队首次完成了人类基因组规模的虚拟筛选项目，覆盖约1万个蛋白靶点、2万个结合口袋，分析超过5亿个小分子，富集出200万余个高潜力活性分子，构建了目前已知最大规模的蛋白-配体筛选数据库。该数据库已面向全球科研社区开放，为基础研究与早期药物发现提供了强大数据支持。</p><p style=\"text-align: justify;\">  DrugCLIP平台现已免费开放，用户无需本地部署，通过网页上传蛋白结构即可启动筛选任务。平台集成口袋/分子编码、向量检索、可视化与结果分析等功能，支持多种分子库调用与自定义上传，广泛适用于科研机构与企业用户。</p><p style=\"text-align: justify;\">  未来，DrugCLIP将与科研产业生态合作伙伴深度合作，在抗癌、传染病、罕见病等方向加速新靶点与First-in-class药物的发现。团队将持续优化引擎性能、拓展支持模态，助力构建一个更智能、高效与普惠的全球药物创新生态。</p>', 4, 100, 1, 2, '', 2, 1, 1, '2024-06-02 23:02:40', '2026-01-10 13:38:51', NULL);
INSERT INTO `sa_article` (`id`, `category_id`, `title`, `author`, `image`, `describe`, `content`, `views`, `sort`, `status`, `is_link`, `link_url`, `is_hot`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (7, 4, '高度重视低空经济为哪般', '新华网', 'https://www.news.cn/tech/20250312/c0453593a495424780c5424c054a1d4d/20250312c0453593a495424780c5424c054a1d4d_2025031215d8945b560d4d169997f7745d0ef56f.jpg', '当前，我国低空经济正处于市场培育初期，关键技术的实用性和商业价值仅得到初步验证，但已彰显出广阔的增长空间', '<p style=\"text-align: justify;\"> &nbsp; &nbsp; &nbsp; &nbsp;近年来，低空经济成为全球发达经济体角逐的重要方向。虽然世界范围内低空经济还处于培育初期阶段，但是美国、日本、欧盟等国家和地区已经重点围绕场景开发应用、交通管理能力、运行技术验证、系统标准体系等方面积极出台和完善相关政策，加快发展低空经济。</p><p style=\"text-align: justify;\">  低空经济是依托低空飞行活动牵引串联的一系列相互关联的产业经济活动，不仅包括上游生产制造飞行器所必需的材料、零部件及分系统的行业企业，还包括中下游低空飞行器组装集成制造和测试试飞、设施配套及低空服务等领域。低空经济产业链条长、产业关联性强、应用场景丰富，具有战略引领性、高增长潜力等显著特征，既可以推动现代农牧业、先进制造业、现代服务业深度融合发展，又能够扩大有效投资、提振消费需求、提升创新能力。世界主要国家高度重视低空经济发展，就是因为看好其发展前景。</p><p style=\"text-align: justify;\">  当前，我国低空经济正处于市场培育初期，关键技术的实用性和商业价值仅得到初步验证，但已彰显出广阔的增长空间。未来随着技术迭代升级和商业模式逐步成熟，低空经济的高增长潜力将会进一步释放，更容易实现相关产业企业的群体性爆发成长，有望成为拉动经济增长的新引擎。</p><p style=\"text-align: justify;\">  一方面，低空飞行器的产业规模体量加快增长、产业生态持续完善。目前，我国无人机制造国际竞争力逐步增强，消费级无人机世界领先优势突出。截至2023年底，我国民用无人机研制企业已超过2300家，量产的无人机产品超过1000款。2023年，我国民用无人机产业规模达到1174.3亿元，同比增长32%。同时，新一代信息技术、新材料、新能源加速与航空科学技术融合发展，推动低空飞行器动力装备及系统、传感器、飞控系统等相关技术加速迭代，绿色高效、安全低噪的飞行器设计、制造与验证技术也持续更新升级。</p><p style=\"text-align: justify;\">  另一方面，体量巨大、类型多样的应用场景持续涌现，牵引低空服务快速释放动能。运营航空器大幅增加，《2023—2024中国民用无人驾驶航空发展报告》显示，截至2024年8月底，我国无人机实名登记数达198.7万架，比2023年底增加72万架；共颁发无人机驾驶员执照22万本，比2023年底增加13.9%。随着影视航拍、航空运动、空中观光游览等低空文旅应用场景快速发展，低空经济能为满足人民群众美好生活需求提供新供给。2023年，横店“航空＋影视＋旅游”交旅融合案例入选第一批交通运输与旅游融合发展十佳案例；2024年，敦煌“飞天”通用航空项目等航空旅游产品案例入选第二批交通运输与旅游融合发展示范案例。低空旅游市场潜力开始显现。</p><p style=\"text-align: justify;\">  同时，低空经济在农业植保、现代物流等行业领域的发展应用不断深入。随着无人机应用技术不断成熟和应用场景持续丰富，“农林牧副渔”多场景作业不断拓展，农业无人机服务市场规模呈蓬勃发展态势。2024年，全国植保无人机的保有量达到25.1万架，作业面积更是高达26.7亿亩次，同比增长近25%。从全球看，上世纪80年代以来，美国农业植保无人机作业渗透率超过50％，日本60％的稻田采用无人机进行植保作业。相较而言，我国农业无人机作业渗透率还比较低，有很大发展空间。在低空物流领域，以无人机为载运工具的无人化配送成为优化城市物流的重要方向，这能有效解决传统物流配送模式面临的劳动力成本、运输成本大幅攀升以及物资配送流通效率低下等诸多问题。在“低空+”领域，低空经济赋能社会治理成效突出，促进巡检、应急救援、城市管理、森林防火、医疗救护等公共服务快速发展。实践中，北京延庆、湖北武汉等地已采用电力线路无人机智能巡检，有效降低了巡检成本，提升了巡检效率。</p><p style=\"text-align: justify;\">  但也要看到，我国低空经济发展还存在一些问题，如统筹发展和安全有短板、产业融合化发展不足、空域管理协同机制尚不健全、基础设施建设相对滞后等。对此，要从突出集群融合、强化科技创新、加强设施建设等方面综合施策，将低空经济的发展潜力充分释放出来。</p><p style=\"text-align: justify;\">  一是突出集群融合，加快培育壮大低空经济产业集群，以市场需求为牵引、以科技创新为驱动，积极完善产业生态、谋划应用场景，推进低空制造业集群化发展。二是强化科技创新，聚焦低空经济创新链薄弱环节，加大科技创新投入，加快提升低空技术支撑能力。三是加强设施建设，构建低空经济基础设施综合保障体系，坚持绿色发展、节约集约，统筹推进通用机场、电动垂直起降飞行器起降场、固定运营基地、飞行服务站等地面配套基础设施建设，推进低空飞行通信、导航、气象监测等信息基础设施建设，加速低空经济智联网络设施建设。此外，还要统筹发展和安全，加强低空飞行器监控防护，强化低空安全技术攻关，提升空域精细化管理能力。坚持包容审慎的安全风险管控理念，建设监管服务体系，建立灵活调配、动态高效的低空空域管理使用机制，增强管理的协同性与联动性。</p>', 11, 100, 1, 2, '', 2, 1, 1, '2024-06-02 23:04:23', '2026-01-10 13:43:44', NULL);
INSERT INTO `sa_article` (`id`, `category_id`, `title`, `author`, `image`, `describe`, `content`, `views`, `sort`, `status`, `is_link`, `link_url`, `is_hot`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (8, 4, '国家发改委成立低空经济发展司', '新华网', 'https://www.news.cn/tech/20241231/3f5396024a9749ee863292c04c7119dc/202412313f5396024a9749ee863292c04c7119dc_2024123101c42d384b83467f835ffd286af095d4.jpg', '近日，低空经济发展司召开推动低空基础设施建设座谈会和推动低空智能网联系统建设专题座谈会', '<p style=\"text-align: justify;\"> &nbsp; &nbsp; &nbsp; 记者从国家发展和改革委员会官方网站获悉，低空经济发展司已正式成立。</p><p style=\"text-align: justify;\">　　低空经济发展司的具体职责是拟订并组织实施低空经济发展战略、中长期发展规划，提出有关政策建议，协调有关重大问题等。</p><p style=\"text-align: justify;\">　　近日，低空经济发展司召开推动低空基础设施建设座谈会和推动低空智能网联系统建设专题座谈会。</p><p style=\"text-align: justify;\">　　在推动低空基础设施建设座谈会上，低空经济发展司负责同志同自然资源部、生态环境部等部委和有关中央企业进行座谈，了解相关领域低空经济典型场景应用和相关基础设施建设发展情况，并就推动低空基础设施有序规划建设进行交流。</p><p style=\"text-align: justify;\">　　在推动低空智能网联系统建设专题座谈会上，低空经济发展司负责同志与通信、导航方面有关专家进行座谈，就低空智能网联系统建设进行交流。</p>', 6, 100, 1, 2, '', 2, 1, 1, '2024-06-02 23:04:23', '2026-01-10 13:42:32', NULL);
COMMIT;

-- ----------------------------
-- Table structure for sa_article_banner
-- ----------------------------
DROP TABLE IF EXISTS `sa_article_banner`;
CREATE TABLE `sa_article_banner` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '编号',
  `banner_type` int DEFAULT NULL COMMENT '类型',
  `image` varchar(1000) DEFAULT NULL COMMENT '图片地址',
  `is_href` tinyint(1) DEFAULT '1' COMMENT '是否链接',
  `url` varchar(255) DEFAULT NULL COMMENT '链接地址',
  `title` varchar(255) DEFAULT NULL COMMENT '标题',
  `status` tinyint(1) DEFAULT '1' COMMENT '状态',
  `sort` int DEFAULT '0' COMMENT '排序',
  `remark` varchar(255) DEFAULT NULL COMMENT '描述',
  `created_by` int DEFAULT NULL COMMENT '创建者',
  `updated_by` int DEFAULT NULL COMMENT '更新者',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='文章轮播图';

-- ----------------------------
-- Records of sa_article_banner
-- ----------------------------
BEGIN;
INSERT INTO `sa_article_banner` (`id`, `banner_type`, `image`, `is_href`, `url`, `title`, `status`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1, 1, 'https://picsum.photos/id/490/640/360', 1, '/blog/1', '探索亚洲的烹饪奇迹', 1, 100, '有一系列名为“新加坡传统烹饪”的食谱，探索了新加坡的美食和文化。它包括新加坡华人、马来人、印度人、欧亚人和土生华人（海峡华人）的美食', 1, 1, '2024-06-02 23:06:37', '2026-01-09 21:51:50', NULL);
INSERT INTO `sa_article_banner` (`id`, `banner_type`, `image`, `is_href`, `url`, `title`, `status`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (2, 1, 'https://picsum.photos/id/29/640/360', 1, '/blog/2', '探索雄伟的山峰', 1, 100, '攀登这座风景如画的山峰的最佳方式是乘坐御在所索道，乘坐15 分钟即可将游客带入空中，欣赏周围一览无余的景观', 1, 1, '2024-06-02 23:06:49', '2026-01-09 21:51:54', NULL);
INSERT INTO `sa_article_banner` (`id`, `banner_type`, `image`, `is_href`, `url`, `title`, `status`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (3, 1, 'https://picsum.photos/id/903/640/360', 1, '/blog/3', '揭秘奇迹', 1, 100, '极光是地球磁场与太阳风相互作用的产物，当太阳风中的带电粒子与地球高层大气中的原子、分子碰撞时，会产生发光现象，形成美丽的极光', 1, 1, '2024-06-02 23:06:56', '2026-01-09 21:53:32', NULL);
COMMIT;

-- ----------------------------
-- Table structure for sa_article_category
-- ----------------------------
DROP TABLE IF EXISTS `sa_article_category`;
CREATE TABLE `sa_article_category` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '编号',
  `parent_id` int NOT NULL DEFAULT '0' COMMENT '父级ID',
  `category_name` varchar(255) NOT NULL COMMENT '分类标题',
  `describe` varchar(255) DEFAULT NULL COMMENT '分类简介',
  `image` varchar(255) DEFAULT NULL COMMENT '分类图片',
  `sort` int unsigned DEFAULT '100' COMMENT '排序',
  `status` tinyint unsigned DEFAULT '1' COMMENT '状态',
  `created_by` int DEFAULT NULL COMMENT '创建者',
  `updated_by` int DEFAULT NULL COMMENT '更新者',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='文章分类表';

-- ----------------------------
-- Records of sa_article_category
-- ----------------------------
BEGIN;
INSERT INTO `sa_article_category` (`id`, `parent_id`, `category_name`, `describe`, `image`, `sort`, `status`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1, 0, '大国科技', '', NULL, 100, 1, 1, 1, '2024-06-02 22:50:51', '2026-01-06 18:03:07', NULL);
INSERT INTO `sa_article_category` (`id`, `parent_id`, `category_name`, `describe`, `image`, `sort`, `status`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (2, 0, '数字经济', '', NULL, 100, 1, 1, 1, '2024-06-02 22:50:56', '2026-01-09 16:54:05', NULL);
INSERT INTO `sa_article_category` (`id`, `parent_id`, `category_name`, `describe`, `image`, `sort`, `status`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (3, 0, '科技快讯', '', NULL, 100, 1, 1, 1, '2024-06-02 22:51:01', '2026-01-07 01:03:37', NULL);
INSERT INTO `sa_article_category` (`id`, `parent_id`, `category_name`, `describe`, `image`, `sort`, `status`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (4, 0, '低空经济', '', NULL, 100, 1, 1, 1, '2024-06-02 22:51:16', '2026-01-06 18:03:14', NULL);
COMMIT;

-- ----------------------------
-- Table structure for sa_member
-- ----------------------------
DROP TABLE IF EXISTS `sa_member`;
CREATE TABLE `sa_member` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '会员ID',
  `username` varchar(50) DEFAULT NULL COMMENT '用户名',
  `nickname` varchar(50) DEFAULT NULL COMMENT '昵称',
  `avatar` varchar(255) DEFAULT NULL COMMENT '头像',
  `mobile` varchar(20) DEFAULT NULL COMMENT '手机号',
  `email` varchar(100) DEFAULT NULL COMMENT '邮箱',
  `password_hash` varchar(100) DEFAULT NULL COMMENT '密码哈希',
  `member_level_id` int NOT NULL DEFAULT '1' COMMENT '会员等级ID',
  `points_balance` int NOT NULL DEFAULT '0' COMMENT '当前积分余额',
  `last_login_ip` varchar(20) DEFAULT NULL COMMENT '最后登录IP',
  `last_login_time` datetime DEFAULT NULL COMMENT '最后登录时间',
  `register_platform_id` tinyint DEFAULT NULL COMMENT '注册平台',
  `status` tinyint NOT NULL DEFAULT '1' COMMENT '状态：1-正常，2-冻结，3-注销',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_mobile` (`mobile`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='会员基础信息表';

-- ----------------------------
-- Records of sa_member
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for sa_member_level
-- ----------------------------
DROP TABLE IF EXISTS `sa_member_level`;
CREATE TABLE `sa_member_level` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '等级ID',
  `level_name` varchar(50) NOT NULL COMMENT '等级名称：如普通会员、白银、黄金',
  `level_code` varchar(20) NOT NULL COMMENT '等级标识：如NORMAL、SILVER、GOLD',
  `min_points` int NOT NULL DEFAULT '0' COMMENT '升级所需最低积分',
  `max_points` int DEFAULT NULL COMMENT '等级上限积分（null表示无上限）',
  `level_icon` varchar(200) DEFAULT NULL COMMENT '等级图标URL（多平台通用）',
  `privileges` text COMMENT '等级权益（JSON格式，如{"discount":0.9,"free_shipping":true}）',
  `sort` int NOT NULL DEFAULT '0' COMMENT '排序',
  `status` tinyint NOT NULL DEFAULT '1' COMMENT '状态',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_level_code` (`level_code`) USING BTREE,
  KEY `idx_min_points` (`min_points`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='会员等级表';

-- ----------------------------
-- Records of sa_member_level
-- ----------------------------
BEGIN;
INSERT INTO `sa_member_level` (`id`, `level_name`, `level_code`, `min_points`, `max_points`, `level_icon`, `privileges`, `sort`, `status`, `remark`, `create_time`, `update_time`, `delete_time`) VALUES (1, '普通会员', 'NORMAL', 0, 10000, '', '', 100, 1, NULL, '2026-01-18 21:09:49', '2026-01-18 21:09:49', NULL);
INSERT INTO `sa_member_level` (`id`, `level_name`, `level_code`, `min_points`, `max_points`, `level_icon`, `privileges`, `sort`, `status`, `remark`, `create_time`, `update_time`, `delete_time`) VALUES (2, '白银会员', 'SILVER', 300, 100000, '', '', 100, 1, NULL, '2026-01-18 21:09:49', '2026-01-18 21:09:49', NULL);
INSERT INTO `sa_member_level` (`id`, `level_name`, `level_code`, `min_points`, `max_points`, `level_icon`, `privileges`, `sort`, `status`, `remark`, `create_time`, `update_time`, `delete_time`) VALUES (3, '黄金会员', 'GOLD', 1000, 1000000, '', '', 100, 1, NULL, '2026-01-18 21:09:49', '2026-01-18 21:09:49', NULL);
COMMIT;

-- ----------------------------
-- Table structure for sa_member_login_log
-- ----------------------------
DROP TABLE IF EXISTS `sa_member_login_log`;
CREATE TABLE `sa_member_login_log` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '日志ID',
  `member_id` bigint NOT NULL COMMENT '会员ID（关联member表）',
  `platform_id` tinyint NOT NULL COMMENT '登录平台ID（关联member_platform表）',
  `login_type` tinyint DEFAULT NULL COMMENT '登录方式',
  `login_ip` varchar(50) DEFAULT NULL COMMENT '登录IP',
  `login_location` varchar(100) DEFAULT NULL COMMENT '登录地点（通过IP解析）',
  `user_agent` text COMMENT '用户代理（浏览器/设备信息）',
  `login_result` tinyint DEFAULT NULL COMMENT '登录结果：1-成功，0-失败',
  `fail_reason` varchar(200) DEFAULT NULL COMMENT '失败原因（如密码错误、账号冻结）',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_member_id` (`member_id`) USING BTREE,
  KEY `idx_platform_time` (`platform_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=47 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='会员登录日志表';

-- ----------------------------
-- Records of sa_member_login_log
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for sa_member_platform
-- ----------------------------
DROP TABLE IF EXISTS `sa_member_platform`;
CREATE TABLE `sa_member_platform` (
  `id` tinyint NOT NULL AUTO_INCREMENT COMMENT '平台ID',
  `platform_name` varchar(50) NOT NULL COMMENT '平台名称：PC、小程序、公众号、H5、钉钉、企业微信',
  `platform_code` varchar(20) NOT NULL COMMENT '平台唯一标识：如PC-WEB、MINI-PROGRAM、WECHAT-OFFICIAL、H5、DINGTALK、WEWORK',
  `status` tinyint NOT NULL DEFAULT '1' COMMENT '状态：1-启用，0-禁用',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_platform_code` (`platform_code`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='多平台配置表';

-- ----------------------------
-- Records of sa_member_platform
-- ----------------------------
BEGIN;
INSERT INTO `sa_member_platform` (`id`, `platform_name`, `platform_code`, `status`, `remark`, `create_time`, `update_time`, `delete_time`) VALUES (1, '邮箱', 'EMAIL', 1, NULL, '2026-01-18 21:09:49', '2026-01-18 21:09:49', NULL);
INSERT INTO `sa_member_platform` (`id`, `platform_name`, `platform_code`, `status`, `remark`, `create_time`, `update_time`, `delete_time`) VALUES (2, '小程序', 'MINI-PROGRAM', 1, NULL, '2026-01-18 21:09:49', '2026-01-18 21:09:49', NULL);
INSERT INTO `sa_member_platform` (`id`, `platform_name`, `platform_code`, `status`, `remark`, `create_time`, `update_time`, `delete_time`) VALUES (3, '微信公众号', 'WECHAT-OFFICIAL', 1, NULL, '2026-01-18 21:09:49', '2026-01-18 21:09:49', NULL);
INSERT INTO `sa_member_platform` (`id`, `platform_name`, `platform_code`, `status`, `remark`, `create_time`, `update_time`, `delete_time`) VALUES (4, '手机号', 'MOBILE', 1, NULL, '2026-01-18 21:09:49', '2026-01-18 21:09:49', NULL);
INSERT INTO `sa_member_platform` (`id`, `platform_name`, `platform_code`, `status`, `remark`, `create_time`, `update_time`, `delete_time`) VALUES (5, '钉钉', 'DINGTALK', 1, NULL, '2026-01-18 21:09:49', '2026-01-18 21:09:49', NULL);
INSERT INTO `sa_member_platform` (`id`, `platform_name`, `platform_code`, `status`, `remark`, `create_time`, `update_time`, `delete_time`) VALUES (6, '企业微信', 'WEWORK', 1, NULL, '2026-01-18 21:09:49', '2026-01-18 21:09:49', NULL);
COMMIT;

-- ----------------------------
-- Table structure for sa_member_platform_rel
-- ----------------------------
DROP TABLE IF EXISTS `sa_member_platform_rel`;
CREATE TABLE `sa_member_platform_rel` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '自增ID',
  `member_id` bigint NOT NULL COMMENT '会员ID（关联member表）',
  `platform_id` tinyint NOT NULL COMMENT '平台ID（关联member_platform表）',
  `platform_openid` varchar(100) NOT NULL COMMENT '平台唯一标识（如微信openid、钉钉unionid）',
  `is_bind` tinyint NOT NULL DEFAULT '1' COMMENT '是否绑定',
  `bind_time` datetime DEFAULT NULL COMMENT '绑定时间',
  `unbind_time` datetime DEFAULT NULL COMMENT '解绑时间（null表示未解绑）',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_platform_openid` (`platform_id`,`platform_openid`) USING BTREE COMMENT '同一平台openid唯一',
  KEY `idx_member_id` (`member_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='会员-平台关联表（多平台账号绑定）';

-- ----------------------------
-- Records of sa_member_platform_rel
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for sa_member_points_log
-- ----------------------------
DROP TABLE IF EXISTS `sa_member_points_log`;
CREATE TABLE `sa_member_points_log` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '记录ID',
  `member_id` int NOT NULL COMMENT '会员ID（关联member表）',
  `platform_id` tinyint NOT NULL COMMENT '操作平台ID（关联member_platform表）',
  `points_change` int NOT NULL COMMENT '积分变动值（正数增加，负数减少）',
  `points_before` int NOT NULL COMMENT '变动前积分',
  `points_after` int NOT NULL COMMENT '变动后积分',
  `operate_type` tinyint NOT NULL COMMENT '操作类型：1-充值，2-消费',
  `operate_desc` varchar(200) NOT NULL COMMENT '操作描述',
  `related_id` int DEFAULT NULL COMMENT '关联业务ID（如订单号、任务ID）',
  `order_no` varchar(100) DEFAULT NULL COMMENT '订单号',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `delete_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_member_id` (`member_id`) USING BTREE,
  KEY `idx_related_id` (`related_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='积分变动记录表';

-- ----------------------------
-- Records of sa_member_points_log
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for sa_member_protocol
-- ----------------------------
DROP TABLE IF EXISTS `sa_member_protocol`;
CREATE TABLE `sa_member_protocol` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '编号',
  `protocol_type` tinyint(1) DEFAULT NULL COMMENT '协议类型',
  `locale` varchar(20) NOT NULL DEFAULT 'zh-CN' COMMENT '语言',
  `title` varchar(255) DEFAULT NULL COMMENT '协议标题',
  `content` text COMMENT '协议内容',
  `status` tinyint(1) DEFAULT '1' COMMENT '状态',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='使用协议';

-- ----------------------------
-- Records of sa_member_protocol
-- ----------------------------
BEGIN;
INSERT INTO `sa_member_protocol` (`id`, `protocol_type`, `locale`, `title`, `content`, `status`, `create_time`, `update_time`, `delete_time`) VALUES (1, 1, 'zh-CN', '用户协议', '<p style=\"text-align: start;\">一、协议的接受与变更</p><p style=\"text-align: start;\"><br></p><ol><li style=\"text-align: start;\">当你点击 “同意” 或 “登录” 按钮，即表示你已充分阅读、理解并接受本协议的全部内容，本协议即对你产生法律约束力。</li><li style=\"text-align: start;\">我们有权根据实际情况随时修改本协议的内容。修改后的协议将在小程序中公布，你可以在登录前查看最新版本的用户协议。如果你继续使用本小程序，则视为你已接受修改后的协议。</li></ol><p style=\"text-align: start;\"><br></p><p style=\"text-align: start;\">二、用户账号</p><p style=\"text-align: start;\"><br></p><ol><li style=\"text-align: start;\">你可以使用手机号码、微信账号等方式登录本小程序。在登录过程中，你需要提供真实、准确、完整的个人信息，并确保这些信息在使用本小程序期间保持有效和更新。</li><li style=\"text-align: start;\">你应当妥善保管自己的登录账号和密码，不得将其转让、出售或出借给他人使用。因你保管不善导致账号被盗用或密码泄露所造成的损失，由你自行承担。</li><li style=\"text-align: start;\">如你发现自己的账号存在异常情况，应立即通知我们，我们将采取相应的措施保护你的账号安全。</li></ol><p style=\"text-align: start;\"><br></p><p style=\"text-align: start;\">三、用户权利与义务</p><p style=\"text-align: start;\"><br></p><p style=\"text-align: start;\">权利</p><ol><li style=\"text-align: start;\">你有权在遵守本协议的前提下，使用本小程序提供的各项服务。</li><li style=\"text-align: start;\">你有权对本小程序的服务提出意见和建议，我们将认真听取并不断改进服务质量。</li></ol><p style=\"text-align: start;\">义务</p><ol><li style=\"text-align: start;\">你应当遵守国家法律法规和本协议的规定，不得利用本小程序从事违法、违规或侵犯他人合法权益的活动。</li><li style=\"text-align: start;\">你不得发布、传播含有虚假、欺诈、诽谤、侮辱、色情、暴力等不良信息的内容。</li><li style=\"text-align: start;\">你应当尊重他人的知识产权，不得未经授权使用他人的作品或商标。</li><li style=\"text-align: start;\">你应当合理使用本小程序的资源，不得进行恶意攻击、破坏系统稳定性等行为。</li></ol><p style=\"text-align: start;\"><br></p><p style=\"text-align: start;\">四、隐私保护</p><p style=\"text-align: start;\"><br></p><ol><li style=\"text-align: start;\">我们重视你的隐私保护，将严格按照法律法规的规定收集、使用和保护你的个人信息。</li><li style=\"text-align: start;\">我们将采取合理的安全措施保护你的个人信息，防止其被泄露、篡改或丢失。但由于不可抗力、黑客攻击等不可预见、不可避免的因素导致的个人信息泄露，我们不承担责任。</li><li style=\"text-align: start;\">你同意我们在必要时可以将你的个人信息提供给第三方服务提供商，以提供更好的服务。但我们将确保第三方服务提供商遵守隐私保护的相关规定。</li></ol><p style=\"text-align: start;\"><br></p><p style=\"text-align: start;\">五、免责声明</p><p style=\"text-align: start;\"><br></p><ol><li style=\"text-align: start;\">本小程序仅提供信息展示和交流平台，我们不对用户发布的内容进行实质性审查。对于用户发布的内容所引起的任何法律纠纷或责任，由发布者自行承担，我们不承担任何责任。</li><li style=\"text-align: start;\">我们不保证本小程序的服务一定能够满足你的需求，也不保证服务的连续性、稳定性和安全性。因系统故障、网络中断、服务器维护等原因导致的服务中断或延迟，我们将尽力及时修复，但不承担由此给你造成的损失。</li><li style=\"text-align: start;\">对于因不可抗力、第三方原因或其他不可预见、不可避免的因素导致的损失，我们不承担责任。</li></ol><p style=\"text-align: start;\"><br></p><p style=\"text-align: start;\">六、知识产权</p><p style=\"text-align: start;\"><br></p><ol><li style=\"text-align: start;\">本小程序的所有内容，包括但不限于文字、图片、音频、视频、软件等，均受知识产权法律法规的保护。未经我们书面授权，你不得擅自使用、复制、传播或修改本小程序的内容。</li><li style=\"text-align: start;\">你在本小程序上发布的内容，其知识产权归你所有。但你同意授予我们在全球范围内免费、非独家、可转让的使用、复制、传播和修改权，以便我们更好地提供服务。</li></ol><p style=\"text-align: start;\"><br></p><p style=\"text-align: start;\">七、协议的终止</p><p style=\"text-align: start;\"><br></p><ol><li style=\"text-align: start;\">你可以随时停止使用本小程序，并注销你的账号。账号注销后，我们将停止为你提供服务，并删除你的个人信息。</li><li style=\"text-align: start;\">如你违反本协议的规定，我们有权暂停或终止你的账号，并保留追究法律责任的权利。</li><li style=\"text-align: start;\">如因不可抗力、法律法规变化等原因导致本小程序无法继续提供服务，我们有权终止本协议。</li></ol><p style=\"text-align: start;\"><br></p><p style=\"text-align: start;\">八、法律适用与争议解决</p><p style=\"text-align: start;\"><br></p><ol><li style=\"text-align: start;\">本协议的签订、履行、解释及争议解决均适用中华人民共和国法律。</li><li style=\"text-align: start;\">如你与我们在本协议的履行过程中发生争议，双方应首先通过友好协商解决。协商不成的，任何一方均有权向有管辖权的人民法院提起诉讼。</li></ol><p style=\"text-align: start;\"><br></p><p style=\"text-align: start;\">九、其他条款</p><p style=\"text-align: start;\"><br></p><ol><li style=\"text-align: start;\">本协议的标题仅为方便阅读而设，不具有法律效力。</li><li style=\"text-align: start;\">本协议的未尽事宜，可由双方另行签订补充协议。补充协议与本协议具有同等法律效力。</li></ol><p style=\"text-align: start;\"><br></p><p style=\"text-align: start;\">再次感谢你使用本小程序！如果你对本协议有任何疑问或建议，请随时联系我们。</p><p style=\"text-align: start;\"><br></p>', 1, '2026-01-18 21:09:49', '2026-01-18 21:09:49', NULL);
INSERT INTO `sa_member_protocol` (`id`, `protocol_type`, `locale`, `title`, `content`, `status`, `create_time`, `update_time`, `delete_time`) VALUES (2, 2, 'zh-CN', '隐私协议', '<h3 style=\"line-height: 2;\">《[小程序名称] 隐私协议》</h3><p><br></p><p style=\"line-height: 2;\">尊敬的用户：</p><p style=\"line-height: 2;\">欢迎使用 [小程序名称]！我们深知个人信息对您的重要性，因此，我们致力于保护您的隐私，并制定本隐私协议，以向您说明我们如何收集、使用、存储和保护您的个人信息。</p><p style=\"line-height: 2;\"><br></p><p style=\"line-height: 2;\">一、信息收集</p><p style=\"line-height: 2;\"><br></p><p style=\"line-height: 2;\">我们可能会在以下情况下收集您的个人信息：</p><ul><li style=\"line-height: 2;\">当您注册或登录小程序时，我们会收集您的用户名、密码、手机号码等信息。</li><li style=\"line-height: 2;\">当您使用小程序的特定功能时，我们可能会收集您的地理位置、设备信息等。</li><li style=\"line-height: 2;\">当您参与小程序的活动或调查时，我们可能会收集您提供的相关信息。</li><li style=\"line-height: 2;\">我们可能会通过以下方式收集您的个人信息：</li><li style=\"line-height: 2;\">您主动提供的信息，例如在注册、填写表单或提交反馈时提供的信息。</li><li style=\"line-height: 2;\">自动收集的信息，例如通过 cookies、日志文件和网络信标等技术收集的信息。</li></ul><p style=\"line-height: 2;\"><br></p><p style=\"line-height: 2;\">二、信息使用</p><p style=\"line-height: 2;\"><br></p><p style=\"line-height: 2;\">我们将仅在以下目的范围内使用您的个人信息：</p><ul><li style=\"line-height: 2;\">为您提供小程序的服务和功能。</li><li style=\"line-height: 2;\">改善小程序的性能和用户体验。</li><li style=\"line-height: 2;\">与您进行沟通和互动，例如回复您的咨询和反馈。</li><li style=\"line-height: 2;\">进行数据分析和市场研究，以改进我们的产品和服务。</li><li style=\"line-height: 2;\">遵守法律法规的要求。</li></ul><p style=\"line-height: 2;\">我们可能会将您的个人信息与第三方共享，但仅在以下情况下：</p><ul><li style=\"line-height: 2;\">经过您的明确同意。</li><li style=\"line-height: 2;\">为了向您提供特定的服务或功能，我们需要与第三方合作，并且该第三方同意遵守本隐私协议的要求。</li><li style=\"line-height: 2;\">为了遵守法律法规的要求或应对法律程序。</li></ul><p style=\"line-height: 2;\"><br></p><p style=\"line-height: 2;\">三、信息存储</p><p style=\"line-height: 2;\"><br></p><ul><li style=\"line-height: 2;\">我们将采取合理的安全措施来保护您的个人信息，包括但不限于加密、访问控制和数据备份等。</li><li style=\"line-height: 2;\">我们将仅在实现本隐私协议所述目的所需的期限内存储您的个人信息。在存储期限届满后，我们将采取适当的方式销毁或匿名化处理您的个人信息。</li></ul><p style=\"line-height: 2;\"><br></p><p style=\"line-height: 2;\">四、信息保护</p><p style=\"line-height: 2;\"><br></p><ul><li style=\"line-height: 2;\">我们将采取技术和组织措施来保护您的个人信息，防止其被未经授权的访问、使用、披露或破坏。</li><li style=\"line-height: 2;\">我们将定期审查和更新我们的安全措施，以确保其有效性。</li><li style=\"line-height: 2;\">尽管我们采取了上述措施，但请注意，互联网传输和存储数据并非完全安全，我们无法保证您的个人信息的绝对安全。</li></ul><p style=\"line-height: 2;\"><br></p><p style=\"line-height: 2;\">五、您的权利</p><p style=\"line-height: 2;\"><br></p><ul><li style=\"line-height: 2;\">您有权访问、更正和删除您的个人信息。您可以通过小程序的设置或联系我们来行使这些权利。</li><li style=\"line-height: 2;\">您有权撤回您对我们使用您的个人信息的同意。您可以通过删除小程序或联系我们来撤回同意。</li><li style=\"line-height: 2;\">您有权要求我们提供关于我们收集、使用和存储您的个人信息的详细信息。您可以通过联系我们来要求提供这些信息。</li></ul><p style=\"line-height: 2;\"><br></p><p style=\"line-height: 2;\">六、未成年人的隐私保护</p><p style=\"line-height: 2;\"><br></p><ul><li style=\"line-height: 2;\">我们非常重视未成年人的隐私保护。如果您是未成年人，请在使用小程序之前获得您的父母或法定监护人的同意。</li><li style=\"line-height: 2;\">我们不会故意收集未成年人的个人信息，除非我们获得了未成年人的父母或法定监护人的明确同意。</li></ul><p style=\"line-height: 2;\"><br></p><p style=\"line-height: 2;\">七、隐私政策的变更</p><p style=\"line-height: 2;\"><br></p><ul><li style=\"line-height: 2;\">我们可能会不时地更新本隐私协议，以反映我们的隐私实践的变化。我们将在小程序上发布更新后的隐私协议，并在适当的时候通知您。</li><li style=\"line-height: 2;\">如果我们对本隐私协议进行重大变更，我们将通过更明显的方式通知您，例如在小程序的首页上发布通知或向您发送电子邮件。</li></ul><p style=\"line-height: 2;\"><br></p><p style=\"line-height: 2;\">八、联系我们</p><p style=\"line-height: 2;\"><br></p><p style=\"line-height: 2;\">如果您对本隐私协议有任何疑问、意见或建议，请随时联系我们。我们的联系方式如下：</p><p style=\"line-height: 2;\"><br></p><p style=\"line-height: 2;\">[联系方式详细信息]</p><p style=\"line-height: 2;\"><br></p><p style=\"line-height: 2;\">再次感谢您对 [小程序名称] 的信任和支持！我们将一如既往地保护您的隐私，为您提供优质的服务。</p><p style=\"line-height: 2;\"><br></p><p style=\"line-height: 2;\">[小程序开发者名称]</p><p style=\"line-height: 2;\"><br></p><p style=\"line-height: 2;\">[具体日期]</p><p style=\"line-height: 2;\"><br></p>', 1, '2026-01-18 21:09:49', '2026-01-18 21:09:49', NULL);
INSERT INTO `sa_member_protocol` (`id`, `protocol_type`, `locale`, `title`, `content`, `status`, `create_time`, `update_time`, `delete_time`) VALUES (3, 3, 'zh-CN', '充值协议', '<p style=\"text-align: start; line-height: 2;\"><span style=\"font-size: 16px;\"><strong>一、协议的确认与接受</strong></span></p><ol><li style=\"text-align: start; line-height: 2;\">本充值协议（以下简称 “本协议”）是你（以下简称 “用户”）与 [小程序名称]（以下简称 “本小程序”）之间就充值相关事项所达成的协议。</li><li style=\"text-align: start; line-height: 2;\">用户在进行充值操作前，应仔细阅读本协议的全部内容。用户点击 “同意” 或进行充值操作即视为用户完全接受本协议项下的全部条款。</li></ol><p style=\"text-align: start; line-height: 2;\"><span style=\"font-size: 16px;\"><strong>二、充值流程</strong></span></p><ol><li style=\"text-align: start; line-height: 2;\">用户选择充值金额及支付方式，按照本小程序提供的充值指引进行操作。</li><li style=\"text-align: start; line-height: 2;\">支付成功后，本小程序将按照用户选择的充值金额为用户的账户进行相应的充值。</li><li style=\"text-align: start; line-height: 2;\">若支付过程中出现异常，用户应及时联系本小程序客服，以便解决问题。</li></ol><p style=\"text-align: start; line-height: 2;\"><span style=\"font-size: 16px;\"><strong>三、充值金额与权益</strong></span></p><ol><li style=\"text-align: start; line-height: 2;\">不同的充值金额可能对应不同的权益和优惠，具体以本小程序的充值页面展示和说明为准。</li><li style=\"text-align: start; line-height: 2;\">用户充值后，可在本小程序内按照相应的规则使用充值金额及享受对应的权益。</li></ol><p style=\"text-align: start; line-height: 2;\"><span style=\"font-size: 16px;\"><strong>四、退款规则</strong></span></p><ol><li style=\"text-align: start; line-height: 2;\">一般情况下，充值成功后，充值金额不予退款，除非因本小程序的技术故障等原因导致充值错误。</li><li style=\"text-align: start; line-height: 2;\">如用户因特殊情况需要退款，应向本小程序客服提出申请，本小程序将根据具体情况进行审核处理。</li></ol><p style=\"text-align: start; line-height: 2;\"><span style=\"font-size: 16px;\"><strong>五、用户的权利与义务</strong></span></p><ol><li style=\"text-align: start; line-height: 2;\">用户应确保充值操作是其本人意愿且使用的支付方式属于其本人合法拥有。</li><li style=\"text-align: start; line-height: 2;\">用户应妥善保管自己的账户信息，不得将其提供给他人使用，因用户自身原因导致账户信息泄露所造成的损失由用户自行承担。</li><li style=\"text-align: start; line-height: 2;\">用户有权按照本协议的约定享受充值后的权益和服务。</li></ol><p style=\"text-align: start; line-height: 2;\"><span style=\"font-size: 16px;\"><strong>六、本小程序的权利与义务</strong></span></p><ol><li style=\"text-align: start; line-height: 2;\">本小程序应确保充值系统的正常运行，保障用户充值过程的安全和顺利。</li><li style=\"text-align: start; line-height: 2;\">本小程序有权根据实际情况调整充值规则、权益和优惠等内容，但应提前在合理的位置进行公示。</li><li style=\"text-align: start; line-height: 2;\">本小程序应保护用户的个人信息和支付安全，不得将其用于非法或未经用户授权的用途。</li></ol><p style=\"text-align: start; line-height: 2;\"><span style=\"font-size: 16px;\"><strong>七、免责条款</strong></span></p><ol><li style=\"text-align: start; line-height: 2;\">因不可抗力（如自然灾害、战争、政府行为等）导致本小程序无法正常提供充值服务的，本小程序不承担责任。</li><li style=\"text-align: start; line-height: 2;\">因用户自身网络问题、设备故障等原因导致充值失败或出现其他问题的，本小程序不承担责任。</li></ol><p style=\"text-align: start; line-height: 2;\"><span style=\"font-size: 16px;\"><strong>八、协议的变更与终止</strong></span></p><ol><li style=\"text-align: start; line-height: 2;\">本小程序有权随时变更本协议的内容，并在本小程序上进行公示。用户继续使用本小程序的充值服务即视为同意变更后的协议。</li><li style=\"text-align: start; line-height: 2;\">用户如有违反本协议的行为，本小程序有权终止为其提供充值服务，并追究其相关法律责任。</li></ol><p style=\"text-align: start; line-height: 2;\"><span style=\"font-size: 16px;\"><strong>九、法律适用与争议解决</strong></span></p><ol><li style=\"text-align: start; line-height: 2;\">本协议的签订、履行、解释及争议解决均适用中华人民共和国法律。</li><li style=\"text-align: start; line-height: 2;\">如双方在本协议的履行过程中发生争议，应首先通过友好协商解决；协商不成的，任何一方均可向有管辖权的人民法院提起诉讼。</li></ol><p style=\"text-align: start; line-height: 2;\"><span style=\"font-size: 16px;\"><strong>十、其他条款</strong></span></p><ol><li style=\"text-align: start; line-height: 2;\">本协议自用户点击 “同意” 或进行充值操作之日起生效。</li><li style=\"text-align: start; line-height: 2;\">本协议的未尽事宜，可由双方另行协商补充。</li></ol>', 1, '2024-09-06 15:14:36', '2026-01-18 23:01:24', NULL);
INSERT INTO `sa_member_protocol` (`id`, `protocol_type`, `locale`, `title`, `content`, `status`, `create_time`, `update_time`, `delete_time`) VALUES (4, 4, 'zh-CN', '使用协议', '<p style=\"line-height: 2;\"><strong>一、协议的范围</strong></p><ol><li style=\"line-height: 2;\">本协议是您（以下简称 “用户”）与 [小程序开发者 / 公司名称]（以下简称 “我们”）之间关于使用 [小程序名称]（以下简称 “本小程序”）的法律协议。</li><li style=\"line-height: 2;\">通过访问或使用本小程序，您即表示同意接受本协议的所有条款和条件的约束。如果您不同意本协议的任何条款，您应立即停止使用本小程序。</li></ol><p style=\"line-height: 2;\"><strong>二、用户资格</strong></p><ol><li style=\"line-height: 2;\">您必须年满 [具体年龄] 周岁以上，具有完全民事行为能力，才能使用本小程序。</li><li style=\"line-height: 2;\">如果您是未成年人，您需要在父母或法定监护人的陪同下使用本小程序。</li></ol><p style=\"line-height: 2;\"><strong>三、小程序的使用</strong></p><ol><li style=\"line-height: 2;\">您可以按照本小程序的功能和用途，合理地使用本小程序提供的各项服务。</li><li style=\"line-height: 2;\">您不得利用本小程序从事任何违法、违规、违背道德或侵犯他人权益的活动，包括但不限于：</li><li style=\"line-height: 2;\">发布、传播或存储任何违法、有害、淫秽、暴力、恐怖、诽谤、侵权或违反公序良俗的信息；</li><li style=\"line-height: 2;\">侵犯他人的知识产权、商业秘密、隐私权或其他合法权益；</li><li style=\"line-height: 2;\">进行欺诈、虚假宣传或误导消费者的行为；</li><li style=\"line-height: 2;\">干扰或破坏本小程序的正常运行，或试图通过非法手段获取本小程序的系统数据或源代码。</li><li style=\"line-height: 2;\">您应遵守本小程序的使用规则和操作流程，不得干扰或破坏本小程序的正常运行。</li></ol><p style=\"line-height: 2;\"><strong>四、用户信息</strong></p><ol><li style=\"line-height: 2;\">在使用本小程序过程中，您可能需要提供一些个人信息。我们将按照相关法律法规的要求，保护您的个人信息安全。</li><li style=\"line-height: 2;\">您应保证提供的个人信息真实、准确、完整，如有变更，应及时更新。</li><li style=\"line-height: 2;\">您同意我们可以收集、使用、存储和披露您的个人信息，用于以下目的：</li></ol><p style=\"text-indent: 2em; line-height: 2;\">&gt;提供本小程序的服务；</p><p style=\"text-indent: 2em; line-height: 2;\">&gt;改进服务质量；</p><p style=\"text-indent: 2em; line-height: 2;\">&gt;进行数据分析；</p><p style=\"text-indent: 2em; line-height: 2;\">&gt;与您沟通，包括发送通知、推广信息等（但您可以随时选择退订）；</p><p style=\"text-indent: 2em; line-height: 2;\">&gt;遵守法律法规的要求。</p><p style=\"line-height: 2;\"><strong>五、知识产权</strong></p><ol><li style=\"line-height: 2;\">本小程序的所有内容，包括但不限于文字、图片、音频、视频、软件等，均受知识产权法律的保护。</li><li style=\"line-height: 2;\">未经我们的书面许可，您不得复制、传播、修改、展示或以其他方式使用本小程序的任何内容。</li></ol><p style=\"line-height: 2;\"><strong>六、免责声明</strong></p><ol><li style=\"line-height: 2;\">本小程序提供的服务是基于 “现状” 和 “可得到” 的基础上提供的，我们不保证本小程序的功能和服务一定能够满足您的需求，也不保证本小程序的运行不会出现故障或错误。</li><li style=\"line-height: 2;\">对于因使用本小程序而导致的任何直接或间接的损失，包括但不限于数据丢失、利润损失、商业机会丧失等，我们不承担任何责任，除非法律另有规定。</li><li style=\"line-height: 2;\">您在使用本小程序时，应自行承担风险，包括但不限于您对本小程序的使用方式、您通过本小程序获取的信息的准确性和可靠性等。</li></ol><p style=\"line-height: 2;\"><strong>七、协议的变更和终止</strong></p><ol><li style=\"line-height: 2;\">我们有权随时修改本协议的条款和条件，并在本小程序上公布。您应定期查看本协议的更新情况，如果您继续使用本小程序，即表示您同意接受修改后的协议。</li><li style=\"line-height: 2;\">如果您违反本协议的任何条款，我们有权终止您的使用资格，并采取相应的法律措施。</li><li style=\"line-height: 2;\">本协议终止后，您应立即停止使用本小程序，并销毁与本小程序相关的任何副本。</li></ol><p style=\"line-height: 2;\"><strong>八、法律适用和争议解决</strong></p><ol><li style=\"line-height: 2;\">本协议的签订、履行、解释及争议解决均适用 [法律适用地] 法律。</li><li style=\"line-height: 2;\">如双方在本协议的履行过程中发生争议，应首先通过友好协商解决；协商不成的，任何一方均有权向有管辖权的人民法院提起诉讼。</li></ol><p style=\"line-height: 2;\"><strong>九、其他条款</strong></p><ol><li style=\"line-height: 2;\">本协议的标题仅为方便阅读而设，不具有任何法律意义。</li><li style=\"line-height: 2;\">本协议的任何条款如被认定为无效或不可执行，不影响其他条款的法律效力。</li><li style=\"line-height: 2;\">我们未行使本协议项下的任何权利，不构成对该权利的放弃。</li></ol>', 1, '2024-09-06 15:14:36', '2024-09-06 15:14:36', NULL);
COMMIT;

-- ----------------------------
-- Table structure for sa_site_info
-- ----------------------------
DROP TABLE IF EXISTS `sa_site_info`;
CREATE TABLE `sa_site_info` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '主键',
  `site_name` varchar(50) DEFAULT NULL COMMENT '站点名称',
  `site_logo` varchar(255) DEFAULT NULL COMMENT '站点logo',
  `site_desc` varchar(255) DEFAULT NULL COMMENT '站点描述',
  `site_keywords` varchar(255) DEFAULT NULL COMMENT '站点关键词',
  `site_copyright` varchar(255) DEFAULT NULL COMMENT '版权信息',
  `site_record_number` varchar(255) DEFAULT NULL COMMENT '备案号',
  `site_config` text COMMENT '站点配置',
  `contact` varchar(255) DEFAULT NULL COMMENT '联系方式',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='站点信息表';

-- ----------------------------
-- Records of sa_site_info
-- ----------------------------
BEGIN;
INSERT INTO `sa_site_info` (`id`, `site_name`, `site_logo`, `site_desc`, `site_keywords`, `site_copyright`, `site_record_number`, `site_config`, `contact`, `remark`, `create_time`, `update_time`, `delete_time`) VALUES (1, 'saiadmin会员系统', 'https://saithink.top/images/logo.png', '开箱即用的高质量中后台管理系统', NULL, '', '', '', '15888888888', '', '2026-01-18 21:09:49', '2026-01-18 23:06:26', NULL);
COMMIT;

-- ----------------------------
-- Table structure for sa_system_attachment
-- ----------------------------
DROP TABLE IF EXISTS `sa_system_attachment`;
CREATE TABLE `sa_system_attachment` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `category_id` int DEFAULT '0' COMMENT '文件分类',
  `storage_mode` smallint DEFAULT '1' COMMENT '存储模式 (1 本地 2 阿里云 3 七牛云 4 腾讯云)',
  `origin_name` varchar(255) DEFAULT NULL COMMENT '原文件名',
  `object_name` varchar(50) DEFAULT NULL COMMENT '新文件名',
  `hash` varchar(64) DEFAULT NULL COMMENT '文件hash',
  `mime_type` varchar(255) DEFAULT NULL COMMENT '资源类型',
  `storage_path` varchar(100) DEFAULT NULL COMMENT '存储目录',
  `suffix` varchar(10) DEFAULT NULL COMMENT '文件后缀',
  `size_byte` bigint DEFAULT NULL COMMENT '字节数',
  `size_info` varchar(50) DEFAULT NULL COMMENT '文件大小',
  `url` varchar(255) DEFAULT NULL COMMENT 'url地址',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `created_by` int DEFAULT NULL COMMENT '创建者',
  `updated_by` int DEFAULT NULL COMMENT '更新者',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `hash` (`hash`) USING BTREE,
  KEY `idx_url` (`url`) USING BTREE,
  KEY `idx_create_time` (`create_time`) USING BTREE,
  KEY `idx_category_id` (`category_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='附件信息表';

-- ----------------------------
-- Records of sa_system_attachment
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for sa_system_category
-- ----------------------------
DROP TABLE IF EXISTS `sa_system_category`;
CREATE TABLE `sa_system_category` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '分类ID',
  `parent_id` int NOT NULL DEFAULT '0' COMMENT '父id',
  `level` varchar(255) DEFAULT NULL COMMENT '组集关系',
  `category_name` varchar(100) NOT NULL DEFAULT '' COMMENT '分类名称',
  `sort` int NOT NULL DEFAULT '0' COMMENT '排序',
  `status` tinyint(1) DEFAULT '1' COMMENT '状态',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `created_by` int DEFAULT NULL COMMENT '创建者',
  `updated_by` int DEFAULT NULL COMMENT '更新者',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `pid` (`parent_id`) USING BTREE,
  KEY `sort` (`sort`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='附件分类表';

-- ----------------------------
-- Records of sa_system_category
-- ----------------------------
BEGIN;
INSERT INTO `sa_system_category` (`id`, `parent_id`, `level`, `category_name`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1, 0, '0,', '全部分类', 100, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_category` (`id`, `parent_id`, `level`, `category_name`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (2, 1, '0,1,', '图片分类', 100, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_category` (`id`, `parent_id`, `level`, `category_name`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (3, 1, '0,1,', '文件分类', 100, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_category` (`id`, `parent_id`, `level`, `category_name`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (4, 1, '0,1,', '系统图片', 100, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_category` (`id`, `parent_id`, `level`, `category_name`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (5, 1, '0,1,', '其他分类', 100, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
COMMIT;

-- ----------------------------
-- Table structure for sa_system_config
-- ----------------------------
DROP TABLE IF EXISTS `sa_system_config`;
CREATE TABLE `sa_system_config` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '编号',
  `group_id` int DEFAULT NULL COMMENT '组id',
  `key` varchar(32) NOT NULL COMMENT '配置键名',
  `value` text COMMENT '配置值',
  `name` varchar(255) DEFAULT NULL COMMENT '配置名称',
  `input_type` varchar(32) DEFAULT NULL COMMENT '数据输入类型',
  `config_select_data` varchar(500) DEFAULT NULL COMMENT '配置选项数据',
  `sort` smallint unsigned DEFAULT '0' COMMENT '排序',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `created_by` int DEFAULT NULL COMMENT '创建人',
  `updated_by` int DEFAULT NULL COMMENT '更新人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`,`key`) USING BTREE,
  KEY `group_id` (`group_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=350 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='参数配置信息表';

-- ----------------------------
-- Records of sa_system_config
-- ----------------------------
BEGIN;
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1, 1, 'site_copyright', 'Copyright © 2024 saithink', '版权信息', 'textarea', NULL, 96, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (2, 1, 'site_desc', '基于vue3 + webman 的极速开发框架', '网站描述', 'textarea', NULL, 97, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (3, 1, 'site_keywords', '后台管理系统', '网站关键字', 'input', NULL, 98, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (4, 1, 'site_name', 'SaiAdmin', '网站名称', 'input', NULL, 99, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (5, 1, 'site_record_number', '9527', '网站备案号', 'input', NULL, 95, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (6, 2, 'upload_allow_file', 'txt,doc,docx,xls,xlsx,ppt,pptx,rar,zip,7z,gz,pdf,wps,md,jpg,png,jpeg,mp4,pem,crt', '文件类型', 'input', NULL, 0, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (7, 2, 'upload_allow_image', 'jpg,jpeg,png,gif,svg,bmp', '图片类型', 'input', NULL, 0, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (8, 2, 'upload_mode', '1', '上传模式', 'select', '[{\"label\":\"本地上传\",\"value\":\"1\"},{\"label\":\"阿里云OSS\",\"value\":\"2\"},{\"label\":\"七牛云\",\"value\":\"3\"},{\"label\":\"腾讯云COS\",\"value\":\"4\"},{\"label\":\"亚马逊S3\",\"value\":\"5\"}]', 99, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (10, 2, 'upload_size', '524288000', '上传大小', 'input', NULL, 88, '单位Byte,1MB=1024*1024Byte', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (11, 2, 'local_root', 'public/storage/', '本地存储路径', 'input', NULL, 0, '本地存储文件路径', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (12, 2, 'local_domain', 'http://127.0.0.1:8787', '本地存储域名', 'input', NULL, 0, 'http://127.0.0.1:8787', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (13, 2, 'local_uri', '/storage/', '本地访问路径', 'input', NULL, 0, '访问是通过domain + uri', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (14, 2, 'qiniu_accessKey', '', '七牛key', 'input', NULL, 0, '七牛云存储secretId', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (15, 2, 'qiniu_secretKey', '', '七牛secret', 'input', NULL, 0, '七牛云存储secretKey', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (16, 2, 'qiniu_bucket', '', '七牛bucket', 'input', NULL, 0, '七牛云存储bucket', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (17, 2, 'qiniu_dirname', '', '七牛dirname', 'input', NULL, 0, '七牛云存储dirname', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (18, 2, 'qiniu_domain', '', '七牛domain', 'input', NULL, 0, '七牛云存储domain', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (19, 2, 'cos_secretId', '', '腾讯Id', 'input', NULL, 0, '腾讯云存储secretId', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (20, 2, 'cos_secretKey', '', '腾讯key', 'input', NULL, 0, '腾讯云secretKey', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (21, 2, 'cos_bucket', '', '腾讯bucket', 'input', NULL, 0, '腾讯云存储bucket', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (22, 2, 'cos_dirname', '', '腾讯dirname', 'input', NULL, 0, '腾讯云存储dirname', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (23, 2, 'cos_domain', '', '腾讯domain', 'input', NULL, 0, '腾讯云存储domain', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (24, 2, 'cos_region', '', '腾讯region', 'input', NULL, 0, '腾讯云存储region', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (25, 2, 'oss_accessKeyId', '', '阿里Id', 'input', NULL, 0, '阿里云存储accessKeyId', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (26, 2, 'oss_accessKeySecret', '', '阿里Secret', 'input', NULL, 0, '阿里云存储accessKeySecret', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (27, 2, 'oss_bucket', '', '阿里bucket', 'input', NULL, 0, '阿里云存储bucket', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (28, 2, 'oss_dirname', '', '阿里dirname', 'input', NULL, 0, '阿里云存储dirname', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (29, 2, 'oss_domain', '', '阿里domain', 'input', NULL, 0, '阿里云存储domain', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (30, 2, 'oss_endpoint', '', '阿里endpoint', 'input', NULL, 0, '阿里云存储endpoint', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (31, 3, 'Host', 'smtp.qq.com', 'SMTP服务器', 'input', '', 100, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (32, 3, 'Port', '465', 'SMTP端口', 'input', '', 100, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (33, 3, 'Username', '', 'SMTP用户名', 'input', '', 100, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (34, 3, 'Password', '', 'SMTP密码', 'input', '', 100, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (35, 3, 'SMTPSecure', 'ssl', 'SMTP验证方式', 'radio', '[\r\n    {\"label\":\"ssl\",\"value\":\"ssl\"},\r\n    {\"label\":\"tsl\",\"value\":\"tsl\"}\r\n]', 100, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (36, 3, 'From', '', '默认发件人', 'input', '', 100, '默认发件的邮箱地址', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (37, 3, 'FromName', '账户注册', '默认发件名称', 'input', '', 100, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (38, 3, 'CharSet', 'UTF-8', '编码', 'input', '', 100, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (39, 3, 'SMTPDebug', '0', '调试模式', 'radio', '[\r\n    {\"label\":\"关闭\",\"value\":\"0\"},\r\n    {\"label\":\"client\",\"value\":\"1\"},\r\n    {\"label\":\"server\",\"value\":\"2\"}\r\n]', 100, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (40, 2, 's3_key', '', 'key', 'input', '', 0, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (41, 2, 's3_secret', '', 'secret', 'input', '', 0, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (42, 2, 's3_bucket', '', 'bucket', 'input', '', 0, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (43, 2, 's3_dirname', '', 'dirname', 'input', '', 0, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (44, 2, 's3_domain', '', 'domain', 'input', '', 0, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (45, 2, 's3_region', '', 'region', 'input', '', 0, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (46, 2, 's3_version', '', 'version', 'input', '', 0, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (47, 2, 's3_use_path_style_endpoint', '', 'path_style_endpoint', 'input', '', 0, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (48, 2, 's3_endpoint', '', 'endpoint', 'input', '', 0, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (49, 2, 's3_acl', '', 'acl', 'input', '', 0, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (302, 4, 'name', '', '小程序名称', 'input', '', 100, '', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:49:06', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (303, 4, 'original_id', '', '原始ID', 'input', '', 90, '', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:49:06', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (304, 4, 'app_id', '', 'AppID', 'input', '', 80, '', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:49:06', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (305, 4, 'app_secret', '', 'AppSecret', 'textarea', '', 70, '', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:49:06', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (306, 5, 'wechat_appid', '', 'AppID', 'input', '', 100, '微信公众号appid', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:49:06', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (307, 5, 'wechat_appsecret', '', 'AppSecret', 'input', '', 90, '微信公众号appsecret', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:49:06', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (308, 5, 'wechat_token', 'easywechat', '微信验证TOKEN', 'input', '', 80, '微信验证TOKEN', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:49:06', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (309, 5, 'wechat_encode', '', '消息加密模式', 'input', '', 70, '消息加密模式', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:49:06', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (310, 5, 'wechat_encodingaeskey', '', 'EncodingAESKey', 'textarea', '', 60, 'aesKey在公众号配置中获取', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:49:06', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (311, 5, 'api', 'https://demo.saithink.top/prod/app/saiuser/index/wechat', '接口地址', 'input', '', 50, '微信公众号用来验证token的api地址', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:49:06', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (312, 6, 'corp_id', '', 'AppID', 'input', '', 100, '企业ID', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:49:06', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (313, 6, 'agent_id', '', 'AgentID', 'input', '', 90, '应用凭证AgentId', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:49:06', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (314, 6, 'app_secret', '', 'AppSecret', 'textarea', '', 80, '应用密钥Secret', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:49:06', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (315, 7, 'corp_id', '', 'CropId', 'input', '', 100, '企业开发编码', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:49:06', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (316, 7, 'agent_id', '', 'AgentID', 'input', '', 90, '应用凭证AgentId', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:49:06', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (317, 7, 'app_key', '', 'AppKey', 'textarea', '', 80, 'AppKey', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:49:06', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (318, 7, 'app_secret', '', 'AppSecret', 'textarea', '', 70, '应用密钥', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:49:06', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (319, 8, 'app_id', '', 'APPID', 'input', '', 100, '必填-支付宝分配的 app_id', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:57:20', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (320, 8, 'app_secret_cert', '', '应用私钥', 'textarea', '', 100, '必填-应用私钥 字符串', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:57:20', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (321, 8, 'app_public_cert_path', '', '应用公钥证书', 'uploadFile', '', 100, '必填-应用公钥证书 路径', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:57:20', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (322, 8, 'alipay_public_cert_path', '', '支付宝公钥证书', 'uploadFile', '', 100, '必填-支付宝公钥证书 路径', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:57:20', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (323, 8, 'alipay_root_cert_path', '', '支付宝根证书', 'uploadFile', '', 100, '必填-支付宝根证书 路径', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:57:20', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (324, 8, 'return_url', '', '同步回调地址', 'input', '', 100, '', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:57:20', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (325, 8, 'notify_url', '', '异步回调地址', 'input', '', 100, '参考-http://localhost:8787/app/saipay/api/notify/alipay', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:57:20', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (326, 8, 'mode', '1', '模式', 'radio', '[{\"label\":\"正常模式\",\"value\":\"0\"},{\"label\":\"沙箱模式\",\"value\":\"1\"},{\"label\":\"服务商模式\",\"value\":\"2\"}]', 100, '', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:57:20', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (327, 8, 'service_provider_id', '', '服务商ID', 'input', '', 100, '服务商模式下的服务商 id，当 mode 为服务商模式时使用该参数', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:57:20', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (328, 9, 'mch_id', '', '商户号', 'input', '', 100, '必填-商户号，服务商模式下为服务商商户号', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:57:20', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (329, 9, 'mch_secret_key', '', 'v3商户秘钥', 'input', '', 100, '必填-v3 商户秘钥', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:57:20', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (330, 9, 'mch_secret_cert', '', '商户私钥', 'uploadFile', '', 100, '必填-商户私钥 ', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:57:20', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (331, 9, 'mch_public_cert_path', '', '商户公钥证书', 'uploadFile', '', 100, '必填-商户公钥证书路径', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:57:20', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (332, 9, 'notify_url', '', '微信回调url', 'input', '', 100, '必填--http://localhost:8787/app/saipay/api/notify/wechat', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:57:20', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (333, 9, 'mp_app_id', '', '公众号app_id', 'input', '', 100, '选填-公众号 的 app_id', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:57:20', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (334, 9, 'mini_app_id', '', '小程序app_id', 'input', '', 100, '选填-小程序 的 app_id', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:57:20', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (335, 9, 'app_id', '', 'app_id', 'input', '', 100, '选填-app 的 app_id', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:57:20', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (336, 9, 'sub_mp_app_id', '', '子公众号app_id', 'input', '', 100, '选填-服务商模式下，子公众号 的 app_id', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:57:20', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (337, 9, 'sub_app_id', '', '子app的app_id', 'input', '', 100, '选填-服务商模式下，子 app 的 app_id', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:57:20', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (338, 9, 'sub_mini_app_id', '', '子小程序app_id', 'input', '', 100, '选填-服务商模式下，子小程序 的 app_id', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:57:20', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (339, 9, 'sub_mch_id', '', '子商户id', 'input', '', 100, '选填-服务商模式下，子商户id', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:57:20', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (340, 9, 'mode', '0', '模式', 'radio', '[\n  {\n    \"label\":\"正常模式\",\n    \"value\":\"0\"\n  },\n  {\n    \"label\":\"服务商模式\",\n    \"value\":\"2\"\n  }\n]', 100, '选填-默认为正常模式', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:57:20', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (341, 9, 'type', 'mini', '关联类型', 'radio', '[{\"label\":\"小程序\", \"value\":\"mini\"},{\"label\":\"公众号\", \"value\":\"mp\"},{\"label\":\"APP\", \"value\":\"app\"}]', 100, '', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:57:20', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (342, 10, 'mch_id', '', '商户号', 'input', '', 100, '必填-商户号', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:57:20', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (343, 10, 'mch_secret_key', '', '商户密钥', 'input', '', 100, '选填-商户密钥：为银联条码支付综合前置平台配置', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:57:20', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (344, 10, 'mch_cert_path', '', '商户公私钥', 'uploadFile', '', 100, '必填-商户公私钥', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:57:20', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (345, 10, 'mch_cert_password', '', '商户公私钥密码', 'input', '', 100, '必填-商户公私钥密码', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:57:20', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (346, 10, 'unipay_public_cert_path', '', '银联公钥证书', 'uploadFile', '', 100, '必填-银联公钥证书路径', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:57:20', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (347, 10, 'return_url', '', '回调地址', 'input', '', 100, '必填', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:57:20', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (348, 10, 'notify_url', '', '通知地址', 'input', '', 100, '必填-http://localhost:8787/app/saipay/api/notify/unipay', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:57:20', NULL);
INSERT INTO `sa_system_config` (`id`, `group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (349, 10, 'mode', '1', '模式', 'input', '', 100, '必填-固定为1', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:57:20', NULL);
COMMIT;

-- ----------------------------
-- Table structure for sa_system_config_group
-- ----------------------------
DROP TABLE IF EXISTS `sa_system_config_group`;
CREATE TABLE `sa_system_config_group` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `name` varchar(50) DEFAULT NULL COMMENT '字典名称',
  `code` varchar(100) DEFAULT NULL COMMENT '字典标示',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `created_by` int DEFAULT NULL COMMENT '创建人',
  `updated_by` int DEFAULT NULL COMMENT '更新人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='参数配置分组表';

-- ----------------------------
-- Records of sa_system_config_group
-- ----------------------------
BEGIN;
INSERT INTO `sa_system_config_group` (`id`, `name`, `code`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1, '站点配置', 'site_config', '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config_group` (`id`, `name`, `code`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (2, '上传配置', 'upload_config', NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config_group` (`id`, `name`, `code`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (3, '邮件服务', 'email_config', NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_config_group` (`id`, `name`, `code`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (4, '微信小程序', 'saiuser_mnp', '', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:49:06', NULL);
INSERT INTO `sa_system_config_group` (`id`, `name`, `code`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (5, '微信公众号', 'saiuser_oa', '', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:49:06', NULL);
INSERT INTO `sa_system_config_group` (`id`, `name`, `code`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (6, '企业微信', 'saiuser_work', '', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:49:06', NULL);
INSERT INTO `sa_system_config_group` (`id`, `name`, `code`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (7, '钉钉H5', 'saiuser_dd', '', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:49:06', NULL);
INSERT INTO `sa_system_config_group` (`id`, `name`, `code`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (8, '支付宝支付', 'alipay_config', '', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:57:20', NULL);
INSERT INTO `sa_system_config_group` (`id`, `name`, `code`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (9, '微信支付', 'wxpay_config', '', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:57:20', NULL);
INSERT INTO `sa_system_config_group` (`id`, `name`, `code`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (10, '银联支付', 'unipay_config', '', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:57:20', NULL);
COMMIT;

-- ----------------------------
-- Table structure for sa_system_dept
-- ----------------------------
DROP TABLE IF EXISTS `sa_system_dept`;
CREATE TABLE `sa_system_dept` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `parent_id` bigint unsigned DEFAULT '0' COMMENT '父级ID，0为根节点',
  `name` varchar(64) NOT NULL COMMENT '部门名称',
  `code` varchar(64) DEFAULT NULL COMMENT '部门编码',
  `leader_id` bigint unsigned DEFAULT NULL COMMENT '部门负责人ID',
  `level` varchar(255) DEFAULT '' COMMENT '祖级列表，格式: 0,1,5, (便于查询子孙节点)',
  `sort` int DEFAULT '0' COMMENT '排序，数字越小越靠前',
  `status` tinyint(1) DEFAULT '1' COMMENT '状态: 1启用, 0禁用',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `created_by` int DEFAULT NULL COMMENT '创建者',
  `updated_by` int DEFAULT NULL COMMENT '更新者',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_parent_id` (`parent_id`) USING BTREE,
  KEY `idx_path` (`level`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1114 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='部门表';

-- ----------------------------
-- Records of sa_system_dept
-- ----------------------------
BEGIN;
INSERT INTO `sa_system_dept` (`id`, `parent_id`, `name`, `code`, `leader_id`, `level`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1, 0, '腾讯集团', 'GROUP', 1, '0,', 100, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_dept` (`id`, `parent_id`, `name`, `code`, `leader_id`, `level`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (2, 1, '总办', 'GMO', NULL, '0,1,', 100, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_dept` (`id`, `parent_id`, `name`, `code`, `leader_id`, `level`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (10, 1, '微信事业群', 'WXG', NULL, '0,1,', 200, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_dept` (`id`, `parent_id`, `name`, `code`, `leader_id`, `level`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (11, 1, '互动娱乐事业群', 'IEG', NULL, '0,1,', 300, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_dept` (`id`, `parent_id`, `name`, `code`, `leader_id`, `level`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (12, 1, '云与智慧产业事业群', 'CSIG', NULL, '0,1,', 400, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_dept` (`id`, `parent_id`, `name`, `code`, `leader_id`, `level`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (101, 10, '微信基础产品部', 'WX_BASE', NULL, '0,1,10,', 100, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_dept` (`id`, `parent_id`, `name`, `code`, `leader_id`, `level`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (102, 10, '微信支付线', 'WX_PAY', NULL, '0,1,10,', 200, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_dept` (`id`, `parent_id`, `name`, `code`, `leader_id`, `level`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (111, 11, '天美工作室群', 'TIMI', NULL, '0,1,11,', 100, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_dept` (`id`, `parent_id`, `name`, `code`, `leader_id`, `level`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (112, 11, '光子工作室群', 'LIGHT', NULL, '0,1,11,', 200, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_dept` (`id`, `parent_id`, `name`, `code`, `leader_id`, `level`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (121, 12, '腾讯云事业部', 'CLOUD', NULL, '0,1,12,', 100, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_dept` (`id`, `parent_id`, `name`, `code`, `leader_id`, `level`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1111, 111, '王者荣耀项目组', 'HOK', NULL, '0,1,11,111,', 100, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_dept` (`id`, `parent_id`, `name`, `code`, `leader_id`, `level`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1112, 111, 'QQ飞车项目组', 'QQ_SPEED', NULL, '0,1,11,111,', 200, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
COMMIT;

-- ----------------------------
-- Table structure for sa_system_dict_data
-- ----------------------------
DROP TABLE IF EXISTS `sa_system_dict_data`;
CREATE TABLE `sa_system_dict_data` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `type_id` int unsigned DEFAULT NULL COMMENT '字典类型ID',
  `label` varchar(50) DEFAULT NULL COMMENT '字典标签',
  `value` varchar(100) DEFAULT NULL COMMENT '字典值',
  `color` varchar(50) DEFAULT NULL COMMENT '字典颜色',
  `code` varchar(100) DEFAULT NULL COMMENT '字典标示',
  `sort` smallint unsigned DEFAULT '0' COMMENT '排序',
  `status` smallint DEFAULT '1' COMMENT '状态 (1正常 2停用)',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `created_by` int DEFAULT NULL COMMENT '创建者',
  `updated_by` int DEFAULT NULL COMMENT '更新者',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `type_id` (`type_id`) USING BTREE,
  KEY `idx_code` (`code`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=60 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='字典数据表';

-- ----------------------------
-- Records of sa_system_dict_data
-- ----------------------------
BEGIN;
INSERT INTO `sa_system_dict_data` (`id`, `type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (2, 2, '本地存储', '1', '#5d87ff', 'upload_mode', 99, 1, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_dict_data` (`id`, `type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (3, 2, '阿里云OSS', '2', '#f9901f', 'upload_mode', 98, 1, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_dict_data` (`id`, `type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (4, 2, '七牛云', '3', '#00ced1', 'upload_mode', 97, 1, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_dict_data` (`id`, `type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (5, 2, '腾讯云COS', '4', '#1d84ff', 'upload_mode', 96, 1, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_dict_data` (`id`, `type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (6, 2, '亚马逊S3', '5', '#ff80c8', 'upload_mode', 95, 1, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_dict_data` (`id`, `type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (7, 3, '正常', '1', '#13deb9', 'data_status', 0, 1, '1为正常', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_dict_data` (`id`, `type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (8, 3, '停用', '2', '#ff4d4f', 'data_status', 0, 1, '2为停用', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_dict_data` (`id`, `type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (9, 4, '统计页面', 'statistics', '#00ced1', 'dashboard', 100, 1, '管理员用', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_dict_data` (`id`, `type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (10, 4, '工作台', 'work', '#ff8c00', 'dashboard', 50, 1, '员工使用', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_dict_data` (`id`, `type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (11, 5, '男', '1', '#5d87ff', 'gender', 0, 1, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_dict_data` (`id`, `type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (12, 5, '女', '2', '#ff4500', 'gender', 0, 1, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_dict_data` (`id`, `type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (13, 5, '未知', '3', '#b48df3', 'gender', 0, 1, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_dict_data` (`id`, `type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (16, 12, '图片', 'image', '#60c041', 'attachment_type', 10, 1, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_dict_data` (`id`, `type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (17, 12, '文档', 'text', '#1d84ff', 'attachment_type', 9, 1, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_dict_data` (`id`, `type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (18, 12, '音频', 'audio', '#00ced1', 'attachment_type', 8, 1, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_dict_data` (`id`, `type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (19, 12, '视频', 'video', '#ff4500', 'attachment_type', 7, 1, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_dict_data` (`id`, `type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (20, 12, '应用程序', 'application', '#ff8c00', 'attachment_type', 6, 1, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_dict_data` (`id`, `type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (21, 13, '目录', '1', '#909399', 'menu_type', 100, 1, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_dict_data` (`id`, `type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (22, 13, '菜单', '2', '#1e90ff', 'menu_type', 100, 1, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_dict_data` (`id`, `type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (23, 13, '按钮', '3', '#ff4500', 'menu_type', 100, 1, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_dict_data` (`id`, `type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (24, 13, '外链', '4', '#00ced1', 'menu_type', 100, 1, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_dict_data` (`id`, `type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (25, 14, '是', '1', '#60c041', 'yes_or_no', 100, 1, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_dict_data` (`id`, `type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (26, 14, '否', '2', '#ff4500', 'yes_or_no', 100, 1, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_dict_data` (`id`, `type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (47, 20, 'URL任务GET', '1', '#5d87ff', 'crontab_task_type', 100, 1, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_dict_data` (`id`, `type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (48, 20, 'URL任务POST', '2', '#00ced1', 'crontab_task_type', 100, 1, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_dict_data` (`id`, `type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (49, 20, '类任务', '3', '#ff8c00', 'crontab_task_type', 100, 1, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_dict_data` (`id`, `type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (50, 24, '用户协议', '1', '#1e90ff', 'app_protocol', 100, 1, '', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:49:06', NULL);
INSERT INTO `sa_system_dict_data` (`id`, `type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (51, 24, '隐私协议', '2', '#1e90ff', 'app_protocol', 100, 1, '', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:49:06', NULL);
INSERT INTO `sa_system_dict_data` (`id`, `type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (52, 24, '充值协议', '3', '#1e90ff', 'app_protocol', 100, 1, '', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:49:06', NULL);
INSERT INTO `sa_system_dict_data` (`id`, `type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (53, 24, '使用协议', '4', '#1e90ff', 'app_protocol', 100, 1, '', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:49:06', NULL);
INSERT INTO `sa_system_dict_data` (`id`, `type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (54, 25, '充值', '1', '#00ced1', 'saiuser_operate_type', 100, 1, '', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:49:06', NULL);
INSERT INTO `sa_system_dict_data` (`id`, `type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (55, 25, '消费', '2', '#ff4500', 'saiuser_operate_type', 100, 1, '', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:49:06', NULL);
INSERT INTO `sa_system_dict_data` (`id`, `type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (56, 26, '支付宝', 'alipay', '#1e90ff', 'saipay_method', 100, 1, '', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:57:20', NULL);
INSERT INTO `sa_system_dict_data` (`id`, `type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (57, 26, '微信支付', 'wechat', '#60c041', 'saipay_method', 100, 1, '', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:57:20', NULL);
INSERT INTO `sa_system_dict_data` (`id`, `type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (58, 26, '抖音支付', 'douyin', '#b48df3', 'saipay_method', 100, 2, '', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:57:20', NULL);
INSERT INTO `sa_system_dict_data` (`id`, `type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (59, 26, '银联支付', 'union', '#ff4500', 'saipay_method', 100, 1, '', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:57:20', NULL);
COMMIT;

-- ----------------------------
-- Table structure for sa_system_dict_type
-- ----------------------------
DROP TABLE IF EXISTS `sa_system_dict_type`;
CREATE TABLE `sa_system_dict_type` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `name` varchar(50) DEFAULT NULL COMMENT '字典名称',
  `code` varchar(100) DEFAULT NULL COMMENT '字典标示',
  `status` smallint DEFAULT '1' COMMENT '状态 (1正常 2停用)',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `created_by` int DEFAULT NULL COMMENT '创建者',
  `updated_by` int DEFAULT NULL COMMENT '更新者',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_code` (`code`) USING BTREE,
  KEY `idx_name` (`name`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=27 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='字典类型表';

-- ----------------------------
-- Records of sa_system_dict_type
-- ----------------------------
BEGIN;
INSERT INTO `sa_system_dict_type` (`id`, `name`, `code`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (2, '存储模式', 'upload_mode', 1, '上传文件存储模式', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_dict_type` (`id`, `name`, `code`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (3, '数据状态', 'data_status', 1, '通用数据状态', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_dict_type` (`id`, `name`, `code`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (4, '后台首页', 'dashboard', 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_dict_type` (`id`, `name`, `code`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (5, '性别', 'gender', 1, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_dict_type` (`id`, `name`, `code`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (12, '附件类型', 'attachment_type', 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_dict_type` (`id`, `name`, `code`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (13, '菜单类型', 'menu_type', 1, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_dict_type` (`id`, `name`, `code`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (14, '是否', 'yes_or_no', 1, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_dict_type` (`id`, `name`, `code`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (20, '定时任务类型', 'crontab_task_type', 1, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_dict_type` (`id`, `name`, `code`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (24, '使用协议', 'app_protocol', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:49:06', NULL);
INSERT INTO `sa_system_dict_type` (`id`, `name`, `code`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (25, '使用协议', 'saiuser_operate_type', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:49:06', NULL);
INSERT INTO `sa_system_dict_type` (`id`, `name`, `code`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (26, '支付方式', 'saipay_method', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-05-29 01:57:20', NULL);
COMMIT;

-- ----------------------------
-- Table structure for sa_system_login_log
-- ----------------------------
DROP TABLE IF EXISTS `sa_system_login_log`;
CREATE TABLE `sa_system_login_log` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `username` varchar(20) DEFAULT NULL COMMENT '用户名',
  `ip` varchar(45) DEFAULT NULL COMMENT '登录IP地址',
  `ip_location` varchar(255) DEFAULT NULL COMMENT 'IP所属地',
  `os` varchar(50) DEFAULT NULL COMMENT '操作系统',
  `browser` varchar(50) DEFAULT NULL COMMENT '浏览器',
  `status` smallint DEFAULT '1' COMMENT '登录状态 (1成功 2失败)',
  `message` varchar(50) DEFAULT NULL COMMENT '提示消息',
  `login_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '登录时间',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `created_by` int DEFAULT NULL COMMENT '创建者',
  `updated_by` int DEFAULT NULL COMMENT '更新者',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `username` (`username`) USING BTREE,
  KEY `idx_create_time` (`create_time`) USING BTREE,
  KEY `idx_login_time` (`login_time`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='登录日志表';

-- ----------------------------
-- Records of sa_system_login_log
-- ----------------------------
BEGIN;
INSERT INTO `sa_system_login_log` (`id`, `username`, `ip`, `ip_location`, `os`, `browser`, `status`, `message`, `login_time`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1, 'admin', '127.0.0.1', '内网IP', 'Mac', 'Chrome', 1, '登录成功', '2026-05-29 01:40:11', NULL, 1, 1, '2026-05-29 01:40:12', '2026-05-29 01:40:12', NULL);
INSERT INTO `sa_system_login_log` (`id`, `username`, `ip`, `ip_location`, `os`, `browser`, `status`, `message`, `login_time`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (2, 'admin', '127.0.0.1', '内网IP', 'Mac', 'Chrome', 1, '登录成功', '2026-05-29 15:48:42', NULL, 1, 1, '2026-05-29 15:48:42', '2026-05-29 15:48:42', NULL);
INSERT INTO `sa_system_login_log` (`id`, `username`, `ip`, `ip_location`, `os`, `browser`, `status`, `message`, `login_time`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (3, 'admin', '127.0.0.1', '内网IP', 'Mac', 'Chrome', 1, '登录成功', '2026-05-29 15:54:17', NULL, 1, 1, '2026-05-29 15:54:18', '2026-05-29 15:54:18', NULL);
INSERT INTO `sa_system_login_log` (`id`, `username`, `ip`, `ip_location`, `os`, `browser`, `status`, `message`, `login_time`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (4, 'admin', '127.0.0.1', '内网IP', 'Mac', 'Chrome', 1, '登录成功', '2026-05-29 16:08:26', NULL, 1, 1, '2026-05-29 16:08:26', '2026-05-29 16:08:26', NULL);
COMMIT;

-- ----------------------------
-- Table structure for sa_system_mail
-- ----------------------------
DROP TABLE IF EXISTS `sa_system_mail`;
CREATE TABLE `sa_system_mail` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '编号',
  `gateway` varchar(50) DEFAULT NULL COMMENT '网关',
  `from` varchar(50) DEFAULT NULL COMMENT '发送人',
  `email` varchar(50) DEFAULT NULL COMMENT '接收人',
  `code` varchar(20) DEFAULT NULL COMMENT '验证码',
  `content` varchar(500) DEFAULT NULL COMMENT '邮箱内容',
  `status` varchar(20) DEFAULT NULL COMMENT '发送状态',
  `response` varchar(500) DEFAULT NULL COMMENT '返回结果',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_create_time` (`create_time`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='邮件记录';

-- ----------------------------
-- Records of sa_system_mail
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for sa_system_menu
-- ----------------------------
DROP TABLE IF EXISTS `sa_system_menu`;
CREATE TABLE `sa_system_menu` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `parent_id` bigint unsigned DEFAULT '0' COMMENT '父级ID',
  `name` varchar(64) NOT NULL COMMENT '菜单名称',
  `code` varchar(64) DEFAULT NULL COMMENT '组件名称',
  `slug` varchar(100) DEFAULT NULL COMMENT '权限标识，如 user:list, user:add',
  `type` tinyint(1) NOT NULL DEFAULT '1' COMMENT '类型: 1目录, 2菜单, 3按钮/API',
  `path` varchar(255) DEFAULT NULL COMMENT '路由地址(前端)或API路径(后端)',
  `component` varchar(255) DEFAULT NULL COMMENT '前端组件路径，如 layout/User',
  `method` varchar(10) DEFAULT NULL COMMENT '请求方式',
  `icon` varchar(64) DEFAULT NULL COMMENT '图标',
  `sort` int DEFAULT '100' COMMENT '排序',
  `link_url` varchar(255) DEFAULT NULL COMMENT '外部链接',
  `is_iframe` tinyint(1) DEFAULT '2' COMMENT '是否iframe',
  `is_keep_alive` tinyint(1) DEFAULT '2' COMMENT '是否缓存',
  `is_hidden` tinyint(1) DEFAULT '2' COMMENT '是否隐藏',
  `is_fixed_tab` tinyint(1) DEFAULT '2' COMMENT '是否固定标签页',
  `is_full_page` tinyint(1) DEFAULT '2' COMMENT '是否全屏',
  `generate_id` int DEFAULT '0' COMMENT '生成id',
  `generate_key` varchar(255) DEFAULT NULL COMMENT '生成key',
  `status` tinyint(1) DEFAULT '1' COMMENT '状态',
  `remark` varchar(255) DEFAULT NULL,
  `created_by` int DEFAULT NULL COMMENT '创建者',
  `updated_by` int DEFAULT NULL COMMENT '更新者',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_parent_id` (`parent_id`) USING BTREE,
  KEY `idx_slug` (`slug`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1104 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='菜单权限表';

-- ----------------------------
-- Records of sa_system_menu
-- ----------------------------
BEGIN;
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1, 0, '仪表盘', 'Dashboard', NULL, 1, '/dashboard', NULL, NULL, 'ri:pie-chart-line', 100, NULL, 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (2, 1, '工作台', 'Console', NULL, 2, 'console', '/dashboard/console', NULL, 'ri:home-smile-2-line', 100, NULL, 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (3, 0, '系统管理', 'System', NULL, 1, '/system', NULL, NULL, 'ri:user-3-line', 100, NULL, 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (4, 3, '用户管理', 'User', NULL, 2, 'user', '/system/user', NULL, 'ri:user-line', 100, NULL, 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (5, 3, '部门管理', 'Dept', NULL, 2, 'dept', '/system/dept', NULL, 'ri:node-tree', 100, NULL, 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (6, 3, '角色管理', 'Role', NULL, 2, 'role', '/system/role', NULL, 'ri:admin-line', 100, NULL, 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (7, 3, '岗位管理', 'Post', '', 2, 'post', '/system/post', NULL, 'ri:signpost-line', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (8, 3, '菜单管理', 'Menu', NULL, 2, 'menu', '/system/menu', NULL, 'ri:menu-line', 100, NULL, 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (10, 0, '运维管理', 'Safeguard', NULL, 1, '/safeguard', '', NULL, 'ri:shield-check-line', 100, NULL, 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (11, 10, '缓存管理', 'Cache', '', 2, 'cache', '/safeguard/cache', NULL, 'ri:keyboard-box-line', 80, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (12, 10, '数据字典', 'Dict', NULL, 2, 'dict', '/safeguard/dict', NULL, 'ri:database-2-line', 100, NULL, 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (13, 10, '附件管理', 'Attachment', '', 2, 'attachment', '/safeguard/attachment', NULL, 'ri:file-cloud-line', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (14, 10, '数据表维护', 'Database', '', 2, 'database', '/safeguard/database', NULL, 'ri:database-line', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (15, 10, '登录日志', 'LoginLog', '', 2, 'login-log', '/safeguard/login-log', NULL, 'ri:login-circle-line', 50, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (16, 10, '操作日志', 'OperLog', '', 2, 'oper-log', '/safeguard/oper-log', NULL, 'ri:shield-keyhole-line', 50, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (17, 10, '邮件日志', 'EmailLog', '', 2, 'email-log', '/safeguard/email-log', NULL, 'ri:mail-line', 50, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (18, 3, '系统设置', 'Config', NULL, 2, 'config', '/system/config', NULL, 'ri:settings-4-line', 100, NULL, 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (19, 0, '官方文档', 'Document', '', 4, '', '', NULL, 'ri:file-copy-2-fill', 90, 'https://saithink.top', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (20, 4, '数据列表', '', 'core:user:index', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (21, 1, '个人中心', 'UserCenter', '', 2, 'user-center', '/dashboard/user-center/index', NULL, 'ri:user-2-line', 100, '', 2, 2, 1, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (22, 4, '添加', '', 'core:user:save', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (23, 4, '修改', '', 'core:user:update', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (24, 4, '读取', '', 'core:user:read', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (25, 4, '删除', '', 'core:user:destroy', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (26, 4, '重置密码', '', 'core:user:password', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (27, 4, '清理缓存', '', 'core:user:cache', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (28, 4, '设置工作台', '', 'core:user:home', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (29, 5, '数据列表', '', 'core:dept:index', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (30, 5, '添加', '', 'core:dept:save', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (31, 5, '修改', '', 'core:dept:update', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (32, 5, '读取', '', 'core:dept:read', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (33, 5, '删除', '', 'core:dept:destroy', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (34, 6, '添加', '', 'core:role:save', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (35, 6, '数据列表', '', 'core:role:index', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (36, 6, '修改', '', 'core:role:update', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (37, 6, '读取', '', 'core:role:read', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (38, 6, '删除', '', 'core:role:destroy', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (39, 6, '菜单权限', '', 'core:role:menu', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (40, 6, '数据权限', '', 'core:role:data', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (41, 7, '数据列表', '', 'core:post:index', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (42, 7, '添加', '', 'core:post:save', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (43, 7, '修改', '', 'core:post:update', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (44, 7, '读取', '', 'core:post:read', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (45, 7, '删除', '', 'core:post:destroy', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (46, 7, '导入', '', 'core:post:import', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (47, 7, '导出', '', 'core:post:export', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (48, 8, '数据列表', '', 'core:menu:index', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (49, 8, '读取', '', 'core:menu:read', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (50, 8, '添加', '', 'core:menu:save', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (51, 8, '修改', '', 'core:menu:update', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (52, 8, '删除', '', 'core:menu:destroy', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (53, 18, '数据列表', '', 'core:config:index', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (54, 18, '管理', '', 'core:config:edit', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (55, 18, '修改', '', 'core:config:update', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (56, 12, '数据列表', '', 'core:dict:index', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (57, 12, '管理', '', 'core:dict:edit', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (58, 13, '数据列表', '', 'core:attachment:index', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (59, 13, '管理', '', 'core:attachment:edit', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (60, 14, '数据表列表', '', 'core:database:index', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (61, 14, '数据表维护', '', 'core:database:edit', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (62, 14, '回收站数据', '', 'core:recycle:index', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (63, 14, '回收站管理', '', 'core:recycle:edit', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (64, 15, '数据列表', '', 'core:logs:login', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (65, 15, '删除', '', 'core:logs:deleteLogin', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (66, 16, '数据列表', '', 'core:logs:Oper', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (67, 16, '删除', '', 'core:logs:deleteOper', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (68, 17, '数据列表', '', 'core:email:index', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (69, 17, '删除', '', 'core:email:destroy', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (70, 10, '服务监控', 'Server', '', 2, 'server', '/safeguard/server', NULL, 'ri:server-line', 90, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (71, 70, '数据列表', '', 'core:server:monitor', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (72, 11, '数据列表', '', 'core:server:cache', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (73, 11, '缓存清理', '', 'core:server:clear', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (74, 2, '登录数据统计', '', 'core:console:list', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (75, 0, '附加权限', 'Permission', '', 1, 'permission', '', NULL, 'ri:apps-2-ai-line', 100, '', 2, 2, 1, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (76, 75, '上传图片', '', 'core:system:uploadImage', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (77, 75, '上传文件', '', 'core:system:uploadFile', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (78, 75, '附件列表', '', 'core:system:resource', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (79, 75, '用户列表', '', 'core:system:user', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (80, 0, '工具', 'Tool', '', 1, '/tool', '', NULL, 'ri:tools-line', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (81, 80, '代码生成', 'Code', '', 2, 'code', '/tool/code', NULL, 'ri:code-s-slash-line', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (82, 80, '定时任务', 'Crontab', '', 2, 'crontab', '/tool/crontab', NULL, 'ri:time-line', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (83, 82, '数据列表', '', 'tool:crontab:index', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (84, 82, '管理', '', 'tool:crontab:edit', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (85, 82, '运行任务', '', 'tool:crontab:run', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (86, 81, '数据列表', '', 'tool:code:index', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (87, 81, '管理', '', 'tool:code:edit', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (88, 0, '插件市场', 'Plugin', '', 2, '/plugin', '/plugin/saipackage/install/index', NULL, 'ri:apps-2-ai-line', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1000, 0, 'SAIAI', 'Saiai', '', 1, '/saiai', '', NULL, 'ri:ai', 100, '', 2, 2, 2, 2, 2, 0, 'pluginsaiaiappapicontrollerIndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1001, 1000, 'AI对话', 'AiChat', '', 2, 'aichat', '/plugin/saiai/index', NULL, 'ri:chat-smile-ai-3-line', 100, '', 2, 2, 2, 2, 2, 0, 'pluginsaiaiappapicontrollerIndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1002, 1000, '管理中心', 'SaiManage', '', 2, 'manage', '', NULL, 'ri:command-fill', 100, '', 2, 2, 2, 2, 2, 0, 'pluginsaiaiappapicontrollerIndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1003, 1002, '对话分组', 'saiai/chat/group', '', 2, 'chat/group', '/plugin/saiai/chat/group/index', NULL, 'ri:home-2-line', 100, '', 2, 2, 2, 2, 2, 0, 'pluginsaiaiappapicontrollerIndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1004, 1003, '列表', NULL, 'saiai:chat:group:index', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'pluginsaiaiappapicontrollerIndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1005, 1003, '保存', NULL, 'saiai:chat:group:save', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'pluginsaiaiappapicontrollerIndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1006, 1003, '更新', NULL, 'saiai:chat:group:update', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'pluginsaiaiappapicontrollerIndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1007, 1003, '读取', NULL, 'saiai:chat:group:read', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'pluginsaiaiappapicontrollerIndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1008, 1003, '删除', NULL, 'saiai:chat:group:destroy', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'pluginsaiaiappapicontrollerIndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1009, 1002, 'AI配置', 'saiai/config/config', '', 2, 'config/config', '/plugin/saiai/config/config/index', NULL, 'ri:settings-3-line', 100, '', 2, 2, 2, 2, 2, 0, 'pluginsaiaiappapicontrollerIndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1010, 1003, '列表', NULL, 'saiai:config:config:index', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'pluginsaiaiappapicontrollerIndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1011, 1003, '保存', NULL, 'saiai:config:config:save', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'pluginsaiaiappapicontrollerIndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1012, 1003, '更新', NULL, 'saiai:config:config:update', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'pluginsaiaiappapicontrollerIndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1013, 1003, '读取', NULL, 'saiai:config:config:read', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'pluginsaiaiappapicontrollerIndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1014, 1003, '删除', NULL, 'saiai:config:config:destroy', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'pluginsaiaiappapicontrollerIndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1015, 0, 'SAIUSER', 'Saiuser', '', 1, '/saiuser', '', NULL, 'ri:shield-user-line', 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1016, 1015, '基础配置', 'Setting', '', 2, 'setting', '', NULL, 'ri:settings-4-line', 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1017, 1016, '使用协议', 'setting/protocol', '', 2, '/saiuser/setting/protocol', '/plugin/saiuser/setting/protocol/index', NULL, 'ri:home-2-line', 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1018, 1017, '列表', NULL, 'saiuser:setting:protocol:index', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1019, 1017, '保存', NULL, 'saiuser:setting:protocol:save', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1020, 1017, '更新', NULL, 'saiuser:setting:protocol:update', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1021, 1017, '读取', NULL, 'saiuser:setting:protocol:read', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1022, 1017, '删除', NULL, 'saiuser:setting:protocol:destroy', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1023, 1016, '平台配置', 'setting/platform', '', 2, '/saiuser/setting/platform', '/plugin/saiuser/setting/platform/index', NULL, 'ri:home-2-line', 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1024, 1023, '列表', NULL, 'saiuser:setting:platform:index', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1025, 1023, '保存', NULL, 'saiuser:setting:platform:save', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1026, 1023, '更新', NULL, 'saiuser:setting:platform:update', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1027, 1023, '读取', NULL, 'saiuser:setting:platform:read', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1028, 1023, '删除', NULL, 'saiuser:setting:platform:destroy', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1029, 1016, '会员等级', 'setting/level', '', 2, '/saiuser/setting/level', '/plugin/saiuser/setting/level/index', NULL, 'ri:home-2-line', 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1030, 1029, '列表', NULL, 'saiuser:setting:level:index', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1031, 1029, '保存', NULL, 'saiuser:setting:level:save', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1032, 1029, '更新', NULL, 'saiuser:setting:level:update', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1033, 1029, '读取', NULL, 'saiuser:setting:level:read', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1034, 1029, '删除', NULL, 'saiuser:setting:level:destroy', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1035, 1016, '站点配置', 'setting/info', '', 2, '/saiuser/setting/info', '/plugin/saiuser/setting/info/index', NULL, 'ri:home-2-line', 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1036, 1035, '列表', NULL, 'saiuser:setting:info:index', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1037, 1035, '更新', NULL, 'saiuser:setting:info:update', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1038, 1035, '读取', NULL, 'saiuser:setting:info:read', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1039, 1015, '会员管理', 'Member', '', 2, 'member', '', NULL, 'ri:user-settings-line', 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1040, 1039, '会员信息', 'member/member', '', 2, '/saiuser/member/member', '/plugin/saiuser/member/member/index', NULL, 'ri:home-2-line', 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1041, 1040, '列表', NULL, 'saiuser:member:member:index', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1042, 1040, '保存', NULL, 'saiuser:member:member:save', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1043, 1040, '更新', NULL, 'saiuser:member:member:update', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1044, 1040, '读取', NULL, 'saiuser:member:member:read', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1045, 1040, '删除', NULL, 'saiuser:member:member:destroy', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1046, 1039, '登录日志', 'member/log', '', 2, '/saiuser/member/log', '/plugin/saiuser/member/log/index', NULL, 'ri:home-2-line', 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1047, 1046, '列表', NULL, 'saiuser:member:log:index', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1048, 1046, '读取', NULL, 'saiuser:member:log:read', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1049, 1046, '删除', NULL, 'saiuser:member:log:destroy', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1050, 1039, '积分日志', 'member/points', '', 2, '/saiuser/member/points', '/plugin/saiuser/member/points/index', NULL, 'ri:home-2-line', 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1051, 1050, '列表', NULL, 'saiuser:member:points:index', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1052, 1050, '读取', NULL, 'saiuser:member:points:read', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1053, 1050, '删除', NULL, 'saiuser:member:points:destroy', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1054, 1039, '平台绑定', 'member/rel', '', 2, '/saiuser/member/rel', '/plugin/saiuser/member/rel/index', NULL, 'ri:home-2-line', 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1055, 1054, '列表', NULL, 'saiuser:member:rel:index', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1056, 1054, '读取', NULL, 'saiuser:member:rel:read', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1057, 1015, '文章管理', 'Cms', '', 2, 'cms', '', NULL, 'ri:file-copy-2-line', 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1058, 1057, '文章分类', 'cms/category', '', 2, '/saiuser/cms/category', '/plugin/saiuser/cms/category/index', NULL, 'ri:home-2-line', 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1059, 1058, '列表', NULL, 'saiuser:cms:category:index', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1060, 1058, '保存', NULL, 'saiuser:cms:category:save', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1061, 1058, '更新', NULL, 'saiuser:cms:category:update', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1062, 1058, '读取', NULL, 'saiuser:cms:category:read', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1063, 1058, '删除', NULL, 'saiuser:cms:category:destroy', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1064, 1057, '轮播列表', 'cms/banner', '', 2, '/saiuser/cms/banner', '/plugin/saiuser/cms/banner/index', NULL, 'ri:home-2-line', 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1065, 1064, '列表', NULL, 'saiuser:cms:banner:index', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1066, 1064, '保存', NULL, 'saiuser:cms:banner:save', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1067, 1064, '更新', NULL, 'saiuser:cms:banner:update', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1068, 1064, '读取', NULL, 'saiuser:cms:banner:read', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1069, 1064, '删除', NULL, 'saiuser:cms:banner:destroy', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1070, 1057, '文章列表', 'cms/article', '', 2, '/saiuser/cms/article', '/plugin/saiuser/cms/article/index', NULL, 'ri:home-2-line', 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1071, 1070, '列表', NULL, 'saiuser:cms:article:index', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1072, 1070, '保存', NULL, 'saiuser:cms:article:save', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1073, 1070, '更新', NULL, 'saiuser:cms:article:update', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1074, 1070, '读取', NULL, 'saiuser:cms:article:read', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1075, 1070, '删除', NULL, 'saiuser:cms:article:destroy', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'plugin\\saiuser\\app\\api\\controller\\IndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1076, 0, 'SAICODE', 'Saicode', '', 1, '/saicode', '', NULL, 'ri:code-block', 100, '', 2, 2, 2, 2, 2, 0, 'pluginsaicodeappcontrollerTableController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1077, 1076, '代码生成', 'Generate', '', 2, 'generate', '/plugin/saicode/index', NULL, 'ri:code-ai-line', 100, '', 2, 2, 2, 2, 2, 0, 'pluginsaicodeappcontrollerTableController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1078, 1077, '管理', '', 'saicode:generate:edit', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, 'pluginsaicodeappcontrollerTableController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1079, 0, 'SAIPAY', 'Saipay', '', 1, '/saipay', '', NULL, 'ri:secure-payment-line', 100, '', 2, 2, 2, 2, 2, 0, 'pluginsaipayappapicontrollerIndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1080, 1079, '订单记录', 'saipay/order', '', 2, 'saipay/order', '/plugin/saipay/order/index', NULL, 'ri:list-unordered', 100, '', 2, 2, 2, 2, 2, 0, 'pluginsaipayappapicontrollerIndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1081, 1080, '列表', NULL, 'saipay:order:index', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'pluginsaipayappapicontrollerIndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1082, 1080, '读取', NULL, 'saipay:order:read', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'pluginsaipayappapicontrollerIndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1083, 1080, '刷新回调', NULL, 'saipay:order:refresh', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'pluginsaipayappapicontrollerIndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1084, 1080, '删除', NULL, 'saipay:order:destroy', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'pluginsaipayappapicontrollerIndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1085, 0, 'SAISMS', 'Saisms', '', 1, '/saisms', '', NULL, 'ri:messenger-line', 100, '', 2, 2, 2, 2, 2, 0, 'pluginsaismsappapicontrollerIndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1086, 1085, '短信配置', 'saisms/config', '', 2, 'saisms/config', '/plugin/saisms/config/index', NULL, 'ri:list-unordered', 100, '', 2, 2, 2, 2, 2, 0, 'pluginsaismsappapicontrollerIndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1087, 1086, '列表', NULL, 'saisms:config:index', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'pluginsaismsappapicontrollerIndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1088, 1086, '保存', NULL, 'saisms:config:save', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'pluginsaismsappapicontrollerIndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1089, 1086, '更新', NULL, 'saisms:config:update', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'pluginsaismsappapicontrollerIndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1090, 1086, '读取', NULL, 'saisms:config:read', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'pluginsaismsappapicontrollerIndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1091, 1086, '删除', NULL, 'saisms:config:destroy', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'pluginsaismsappapicontrollerIndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1092, 1086, '修改状态', NULL, 'saisms:config:changeStatus', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'pluginsaismsappapicontrollerIndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1093, 1085, '短信标签', 'saisms/tag', '', 2, 'saisms/tag', '/plugin/saisms/tag/index', NULL, 'ri:list-unordered', 100, '', 2, 2, 2, 2, 2, 0, 'pluginsaismsappapicontrollerIndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1094, 1093, '列表', NULL, 'saisms:tag:index', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'pluginsaismsappapicontrollerIndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1095, 1093, '保存', NULL, 'saisms:tag:save', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'pluginsaismsappapicontrollerIndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1096, 1093, '更新', NULL, 'saisms:tag:update', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'pluginsaismsappapicontrollerIndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1097, 1093, '读取', NULL, 'saisms:tag:read', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'pluginsaismsappapicontrollerIndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1098, 1093, '删除', NULL, 'saisms:tag:destroy', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'pluginsaismsappapicontrollerIndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1099, 1093, '发送测试', NULL, 'saisms:tag:testTag', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'pluginsaismsappapicontrollerIndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1100, 1085, '短信记录', 'saisms/record', '', 2, 'saisms/record', '/plugin/saisms/record/index', NULL, 'ri:list-unordered', 100, '', 2, 2, 2, 2, 2, 0, 'pluginsaismsappapicontrollerIndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1101, 1100, '列表', NULL, 'saisms:record:index', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'pluginsaismsappapicontrollerIndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1102, 1100, '读取', NULL, 'saisms:record:read', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'pluginsaismsappapicontrollerIndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1103, 1100, '删除', NULL, 'saisms:record:destroy', 3, NULL, NULL, NULL, NULL, 100, '', 2, 2, 2, 2, 2, 0, 'pluginsaismsappapicontrollerIndexController', 1, '', 1, 1, '2026-01-01 11:11:11', '2026-01-01 11:11:11', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1104, 10, '数据库导入导出', 'DatabaseBackup', '', 2, 'database-backup', '/safeguard/database-backup', NULL, 'ri:database-2-line', 90, '', 2, 2, 2, 2, 2, 0, NULL, 1, '', 1, 1, '2026-06-03 00:00:00', '2026-06-03 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1105, 1104, '列表', '', 'core:database-backup:index', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, '', 1, 1, '2026-06-03 00:00:00', '2026-06-03 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1106, 1104, '导出', '', 'core:database-backup:export', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, '', 1, 1, '2026-06-03 00:00:00', '2026-06-03 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1107, 1104, '导入', '', 'core:database-backup:import', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, '', 1, 1, '2026-06-03 00:00:00', '2026-06-03 00:00:00', NULL);
INSERT INTO `sa_system_menu` (`id`, `parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1108, 1104, '删除备份', '', 'core:database-backup:delete', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, '', 1, 1, '2026-06-03 00:00:00', '2026-06-03 00:00:00', NULL);
COMMIT;

-- ----------------------------
-- Table structure for sa_system_oper_log
-- ----------------------------
DROP TABLE IF EXISTS `sa_system_oper_log`;
CREATE TABLE `sa_system_oper_log` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `username` varchar(20) DEFAULT NULL COMMENT '用户名',
  `app` varchar(50) DEFAULT NULL COMMENT '应用名称',
  `method` varchar(20) DEFAULT NULL COMMENT '请求方式',
  `router` varchar(500) DEFAULT NULL COMMENT '请求路由',
  `service_name` varchar(30) DEFAULT NULL COMMENT '业务名称',
  `ip` varchar(45) DEFAULT NULL COMMENT '请求IP地址',
  `ip_location` varchar(255) DEFAULT NULL COMMENT 'IP所属地',
  `request_data` text COMMENT '请求数据',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `created_by` int DEFAULT NULL COMMENT '创建者',
  `updated_by` int DEFAULT NULL COMMENT '更新者',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `username` (`username`) USING BTREE,
  KEY `idx_create_time` (`create_time`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=20 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='操作日志表';

-- ----------------------------
-- Records of sa_system_oper_log
-- ----------------------------
BEGIN;
INSERT INTO `sa_system_oper_log` (`id`, `username`, `app`, `method`, `router`, `service_name`, `ip`, `ip_location`, `request_data`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1, 'admin', 'saipackage', 'POST', '/tool/install/online/storeLogin', '未命名业务', '127.0.0.1', '内网IP', '{\"username\":\"3095300995@qq.com\",\"password\":\"******\",\"code\":\"vfmv\",\"uuid\":\"bec9deee-2900-44f7-aa5e-703c45dfa3b1\"}', NULL, 1, 1, '2026-05-29 01:40:29', '2026-05-29 01:40:29', NULL);
INSERT INTO `sa_system_oper_log` (`id`, `username`, `app`, `method`, `router`, `service_name`, `ip`, `ip_location`, `request_data`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (2, 'admin', 'saipackage', 'POST', '/tool/install/online/storeDownloadApp', '未命名业务', '127.0.0.1', '内网IP', '{\"token\":\"eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJ3ZWJtYW4udGlueXdhbi5jbiIsImF1ZCI6IndlYm1hbi50aW55d2FuLmNuIiwiaWF0IjoxNzc5OTkwMDI5LCJuYmYiOjE3Nzk5OTAwMjksImV4cCI6MTc4MDA3NjQyOSwiZXh0ZW5kIjp7ImFjY2Vzc19leHAiOjg2NDAwLCJpZCI6MzUsInVzZXJuYW1lIjoibGlud2VpeGluIiwicGxhdCI6InNhaXVzZXIiLCJ0eXBlIjoxfX0.BG7j4EmQgV1_T9U4wddn0KrNP6diu1KvQHAMa7RlYUs\",\"id\":47}', NULL, 1, 1, '2026-05-29 01:40:43', '2026-05-29 01:40:43', NULL);
INSERT INTO `sa_system_oper_log` (`id`, `username`, `app`, `method`, `router`, `service_name`, `ip`, `ip_location`, `request_data`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (3, 'admin', 'saipackage', 'POST', '/app/saipackage/install/install', '未命名业务', '127.0.0.1', '内网IP', '{\"appName\":\"saiai\"}', NULL, 1, 1, '2026-05-29 01:40:46', '2026-05-29 01:40:46', NULL);
INSERT INTO `sa_system_oper_log` (`id`, `username`, `app`, `method`, `router`, `service_name`, `ip`, `ip_location`, `request_data`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (4, 'admin', 'saipackage', 'POST', '/app/saipackage/install/reload', '未命名业务', '127.0.0.1', '内网IP', '[]', NULL, 1, 1, '2026-05-29 01:40:46', '2026-05-29 01:40:46', NULL);
INSERT INTO `sa_system_oper_log` (`id`, `username`, `app`, `method`, `router`, `service_name`, `ip`, `ip_location`, `request_data`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (5, 'admin', 'saipackage', 'POST', '/app/saipackage/install/install', '未命名业务', '127.0.0.1', '内网IP', '{\"appName\":\"saiai\"}', NULL, 1, 1, '2026-05-29 01:40:50', '2026-05-29 01:40:50', NULL);
INSERT INTO `sa_system_oper_log` (`id`, `username`, `app`, `method`, `router`, `service_name`, `ip`, `ip_location`, `request_data`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (6, 'admin', 'saipackage', 'POST', '/tool/install/online/storeDownloadApp', '未命名业务', '127.0.0.1', '内网IP', '{\"token\":\"eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJ3ZWJtYW4udGlueXdhbi5jbiIsImF1ZCI6IndlYm1hbi50aW55d2FuLmNuIiwiaWF0IjoxNzc5OTkwMDI5LCJuYmYiOjE3Nzk5OTAwMjksImV4cCI6MTc4MDA3NjQyOSwiZXh0ZW5kIjp7ImFjY2Vzc19leHAiOjg2NDAwLCJpZCI6MzUsInVzZXJuYW1lIjoibGlud2VpeGluIiwicGxhdCI6InNhaXVzZXIiLCJ0eXBlIjoxfX0.BG7j4EmQgV1_T9U4wddn0KrNP6diu1KvQHAMa7RlYUs\",\"id\":41}', NULL, 1, 1, '2026-05-29 01:49:03', '2026-05-29 01:49:03', NULL);
INSERT INTO `sa_system_oper_log` (`id`, `username`, `app`, `method`, `router`, `service_name`, `ip`, `ip_location`, `request_data`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (7, 'admin', 'saipackage', 'POST', '/app/saipackage/install/install', '未命名业务', '127.0.0.1', '内网IP', '{\"appName\":\"saiuser\"}', NULL, 1, 1, '2026-05-29 01:49:06', '2026-05-29 01:49:06', NULL);
INSERT INTO `sa_system_oper_log` (`id`, `username`, `app`, `method`, `router`, `service_name`, `ip`, `ip_location`, `request_data`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (8, 'admin', 'saipackage', 'POST', '/app/saipackage/install/reload', '未命名业务', '127.0.0.1', '内网IP', '[]', NULL, 1, 1, '2026-05-29 01:49:06', '2026-05-29 01:49:06', NULL);
INSERT INTO `sa_system_oper_log` (`id`, `username`, `app`, `method`, `router`, `service_name`, `ip`, `ip_location`, `request_data`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (9, 'admin', 'saipackage', 'POST', '/tool/install/online/storeDownloadApp', '未命名业务', '127.0.0.1', '内网IP', '{\"token\":\"eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJ3ZWJtYW4udGlueXdhbi5jbiIsImF1ZCI6IndlYm1hbi50aW55d2FuLmNuIiwiaWF0IjoxNzc5OTkwMDI5LCJuYmYiOjE3Nzk5OTAwMjksImV4cCI6MTc4MDA3NjQyOSwiZXh0ZW5kIjp7ImFjY2Vzc19leHAiOjg2NDAwLCJpZCI6MzUsInVzZXJuYW1lIjoibGlud2VpeGluIiwicGxhdCI6InNhaXVzZXIiLCJ0eXBlIjoxfX0.BG7j4EmQgV1_T9U4wddn0KrNP6diu1KvQHAMa7RlYUs\",\"id\":46}', NULL, 1, 1, '2026-05-29 01:57:00', '2026-05-29 01:57:00', NULL);
INSERT INTO `sa_system_oper_log` (`id`, `username`, `app`, `method`, `router`, `service_name`, `ip`, `ip_location`, `request_data`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (10, 'admin', 'saipackage', 'POST', '/app/saipackage/install/install', '未命名业务', '127.0.0.1', '内网IP', '{\"appName\":\"saicode\"}', NULL, 1, 1, '2026-05-29 01:57:03', '2026-05-29 01:57:03', NULL);
INSERT INTO `sa_system_oper_log` (`id`, `username`, `app`, `method`, `router`, `service_name`, `ip`, `ip_location`, `request_data`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (11, 'admin', 'saipackage', 'POST', '/app/saipackage/install/reload', '未命名业务', '127.0.0.1', '内网IP', '[]', NULL, 1, 1, '2026-05-29 01:57:03', '2026-05-29 01:57:03', NULL);
INSERT INTO `sa_system_oper_log` (`id`, `username`, `app`, `method`, `router`, `service_name`, `ip`, `ip_location`, `request_data`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (12, 'admin', 'saipackage', 'POST', '/tool/install/online/storeDownloadApp', '未命名业务', '127.0.0.1', '内网IP', '{\"token\":\"eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJ3ZWJtYW4udGlueXdhbi5jbiIsImF1ZCI6IndlYm1hbi50aW55d2FuLmNuIiwiaWF0IjoxNzc5OTkwMDI5LCJuYmYiOjE3Nzk5OTAwMjksImV4cCI6MTc4MDA3NjQyOSwiZXh0ZW5kIjp7ImFjY2Vzc19leHAiOjg2NDAwLCJpZCI6MzUsInVzZXJuYW1lIjoibGlud2VpeGluIiwicGxhdCI6InNhaXVzZXIiLCJ0eXBlIjoxfX0.BG7j4EmQgV1_T9U4wddn0KrNP6diu1KvQHAMa7RlYUs\",\"id\":38}', NULL, 1, 1, '2026-05-29 01:57:17', '2026-05-29 01:57:17', NULL);
INSERT INTO `sa_system_oper_log` (`id`, `username`, `app`, `method`, `router`, `service_name`, `ip`, `ip_location`, `request_data`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (13, 'admin', 'saipackage', 'POST', '/app/saipackage/install/install', '未命名业务', '127.0.0.1', '内网IP', '{\"appName\":\"saipay\"}', NULL, 1, 1, '2026-05-29 01:57:21', '2026-05-29 01:57:21', NULL);
INSERT INTO `sa_system_oper_log` (`id`, `username`, `app`, `method`, `router`, `service_name`, `ip`, `ip_location`, `request_data`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (14, 'admin', 'saipackage', 'POST', '/app/saipackage/install/reload', '未命名业务', '127.0.0.1', '内网IP', '[]', NULL, 1, 1, '2026-05-29 01:57:21', '2026-05-29 01:57:21', NULL);
INSERT INTO `sa_system_oper_log` (`id`, `username`, `app`, `method`, `router`, `service_name`, `ip`, `ip_location`, `request_data`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (15, 'admin', 'saipackage', 'POST', '/tool/install/online/storeDownloadApp', '未命名业务', '127.0.0.1', '内网IP', '{\"token\":\"eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJ3ZWJtYW4udGlueXdhbi5jbiIsImF1ZCI6IndlYm1hbi50aW55d2FuLmNuIiwiaWF0IjoxNzc5OTkwMDI5LCJuYmYiOjE3Nzk5OTAwMjksImV4cCI6MTc4MDA3NjQyOSwiZXh0ZW5kIjp7ImFjY2Vzc19leHAiOjg2NDAwLCJpZCI6MzUsInVzZXJuYW1lIjoibGlud2VpeGluIiwicGxhdCI6InNhaXVzZXIiLCJ0eXBlIjoxfX0.BG7j4EmQgV1_T9U4wddn0KrNP6diu1KvQHAMa7RlYUs\",\"id\":40}', NULL, 1, 1, '2026-05-29 01:58:20', '2026-05-29 01:58:20', NULL);
INSERT INTO `sa_system_oper_log` (`id`, `username`, `app`, `method`, `router`, `service_name`, `ip`, `ip_location`, `request_data`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (16, 'admin', 'saipackage', 'POST', '/app/saipackage/install/install', '未命名业务', '127.0.0.1', '内网IP', '{\"appName\":\"saisms\"}', NULL, 1, 1, '2026-05-29 01:59:41', '2026-05-29 01:59:41', NULL);
INSERT INTO `sa_system_oper_log` (`id`, `username`, `app`, `method`, `router`, `service_name`, `ip`, `ip_location`, `request_data`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (17, 'admin', 'saipackage', 'POST', '/app/saipackage/install/reload', '未命名业务', '127.0.0.1', '内网IP', '[]', NULL, 1, 1, '2026-05-29 01:59:41', '2026-05-29 01:59:41', NULL);
INSERT INTO `sa_system_oper_log` (`id`, `username`, `app`, `method`, `router`, `service_name`, `ip`, `ip_location`, `request_data`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (18, 'admin', 'saipackage', 'POST', '/tool/install/online/storeDownloadApp', '未命名业务', '127.0.0.1', '内网IP', '{\"token\":\"eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJ3ZWJtYW4udGlueXdhbi5jbiIsImF1ZCI6IndlYm1hbi50aW55d2FuLmNuIiwiaWF0IjoxNzc5OTkwMDI5LCJuYmYiOjE3Nzk5OTAwMjksImV4cCI6MTc4MDA3NjQyOSwiZXh0ZW5kIjp7ImFjY2Vzc19leHAiOjg2NDAwLCJpZCI6MzUsInVzZXJuYW1lIjoibGlud2VpeGluIiwicGxhdCI6InNhaXVzZXIiLCJ0eXBlIjoxfX0.BG7j4EmQgV1_T9U4wddn0KrNP6diu1KvQHAMa7RlYUs\",\"id\":39}', NULL, 1, 1, '2026-05-29 02:00:18', '2026-05-29 02:00:18', NULL);
INSERT INTO `sa_system_oper_log` (`id`, `username`, `app`, `method`, `router`, `service_name`, `ip`, `ip_location`, `request_data`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (19, 'admin', 'saipackage', 'POST', '/tool/install/online/storeDownloadApp', '未命名业务', '127.0.0.1', '内网IP', '{\"token\":\"eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJ3ZWJtYW4udGlueXdhbi5jbiIsImF1ZCI6IndlYm1hbi50aW55d2FuLmNuIiwiaWF0IjoxNzc5OTkwMDI5LCJuYmYiOjE3Nzk5OTAwMjksImV4cCI6MTc4MDA3NjQyOSwiZXh0ZW5kIjp7ImFjY2Vzc19leHAiOjg2NDAwLCJpZCI6MzUsInVzZXJuYW1lIjoibGlud2VpeGluIiwicGxhdCI6InNhaXVzZXIiLCJ0eXBlIjoxfX0.BG7j4EmQgV1_T9U4wddn0KrNP6diu1KvQHAMa7RlYUs\",\"id\":39}', NULL, 1, 1, '2026-05-29 02:00:34', '2026-05-29 02:00:34', NULL);
COMMIT;

-- ----------------------------
-- Table structure for sa_system_post
-- ----------------------------
DROP TABLE IF EXISTS `sa_system_post`;
CREATE TABLE `sa_system_post` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `name` varchar(50) DEFAULT NULL COMMENT '岗位名称',
  `code` varchar(100) DEFAULT NULL COMMENT '岗位代码',
  `sort` smallint unsigned DEFAULT '0' COMMENT '排序',
  `status` smallint DEFAULT '1' COMMENT '状态 (1正常 2停用)',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `created_by` int DEFAULT NULL COMMENT '创建者',
  `updated_by` int DEFAULT NULL COMMENT '更新者',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=87 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='岗位信息表';

-- ----------------------------
-- Records of sa_system_post
-- ----------------------------
BEGIN;
INSERT INTO `sa_system_post` (`id`, `name`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1, '司机岗', 'driver', 100, 1, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_post` (`id`, `name`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (2, '保安岗', 'security', 100, 1, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
COMMIT;

-- ----------------------------
-- Table structure for sa_system_role
-- ----------------------------
DROP TABLE IF EXISTS `sa_system_role`;
CREATE TABLE `sa_system_role` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(64) NOT NULL COMMENT '角色名称',
  `code` varchar(64) NOT NULL COMMENT '角色标识(英文唯一)，如: hr_manager',
  `level` int DEFAULT '1' COMMENT '角色级别(1-100)：用于行政控制，不可操作级别>=自己的角色',
  `data_scope` tinyint DEFAULT '1' COMMENT '数据范围: 1全部, 2本部门及下属, 3本部门, 4仅本人, 5自定义',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `sort` int DEFAULT '100',
  `status` tinyint(1) DEFAULT '1' COMMENT '状态: 1启用, 0禁用',
  `created_by` int DEFAULT NULL COMMENT '创建者',
  `updated_by` int DEFAULT NULL COMMENT '更新者',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_slug` (`code`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='角色表';

-- ----------------------------
-- Records of sa_system_role
-- ----------------------------
BEGIN;
INSERT INTO `sa_system_role` (`id`, `name`, `code`, `level`, `data_scope`, `remark`, `sort`, `status`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1, '超级管理员', 'super_admin', 100, 1, '系统维护者，拥有所有权限', 100, 1, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_role` (`id`, `name`, `code`, `level`, `data_scope`, `remark`, `sort`, `status`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (2, '集团总裁', 'ceo', 90, 1, '查看全集团数据', 100, 1, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_role` (`id`, `name`, `code`, `level`, `data_scope`, `remark`, `sort`, `status`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (3, 'BG总裁', 'bg_president', 80, 2, '', 100, 1, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_role` (`id`, `name`, `code`, `level`, `data_scope`, `remark`, `sort`, `status`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (4, '部门总经理', 'gm', 60, 2, '', 100, 1, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_role` (`id`, `name`, `code`, `level`, `data_scope`, `remark`, `sort`, `status`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (5, '组长', 'team_leader', 30, 3, '', 100, 1, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_role` (`id`, `name`, `code`, `level`, `data_scope`, `remark`, `sort`, `status`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (6, '普通员工', 'staff', 10, 4, '', 100, 1, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
COMMIT;

-- ----------------------------
-- Table structure for sa_system_role_dept
-- ----------------------------
DROP TABLE IF EXISTS `sa_system_role_dept`;
CREATE TABLE `sa_system_role_dept` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `role_id` bigint unsigned NOT NULL,
  `dept_id` bigint unsigned NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_role_id` (`role_id`) USING BTREE,
  KEY `idx_dept_id` (`dept_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='角色-自定义数据权限关联';

-- ----------------------------
-- Records of sa_system_role_dept
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for sa_system_role_menu
-- ----------------------------
DROP TABLE IF EXISTS `sa_system_role_menu`;
CREATE TABLE `sa_system_role_menu` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `role_id` bigint unsigned NOT NULL,
  `menu_id` bigint unsigned NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_menu_id` (`menu_id`) USING BTREE,
  KEY `idx_role_id` (`role_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='角色权限关联';

-- ----------------------------
-- Records of sa_system_role_menu
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for sa_system_user
-- ----------------------------
DROP TABLE IF EXISTS `sa_system_user`;
CREATE TABLE `sa_system_user` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(64) NOT NULL COMMENT '登录账号',
  `password` varchar(255) NOT NULL COMMENT '加密密码',
  `realname` varchar(64) DEFAULT NULL COMMENT '真实姓名',
  `gender` varchar(10) DEFAULT NULL COMMENT '性别',
  `avatar` varchar(255) DEFAULT NULL COMMENT '头像',
  `email` varchar(128) DEFAULT NULL COMMENT '邮箱',
  `phone` varchar(20) DEFAULT NULL COMMENT '手机号',
  `signed` varchar(255) DEFAULT NULL COMMENT '个性签名',
  `dashboard` varchar(255) DEFAULT 'work' COMMENT '工作台',
  `dept_id` bigint unsigned DEFAULT NULL COMMENT '主归属部门',
  `is_super` tinyint(1) DEFAULT '0' COMMENT '是否超级管理员: 1是(跳过权限检查), 0否',
  `status` tinyint(1) DEFAULT '1' COMMENT '状态: 1启用, 0禁用',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `login_time` timestamp NULL DEFAULT NULL COMMENT '最后登录时间',
  `login_ip` varchar(45) DEFAULT NULL COMMENT '最后登录IP',
  `created_by` int DEFAULT NULL COMMENT '创建者',
  `updated_by` int DEFAULT NULL COMMENT '更新者',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_username` (`username`) USING BTREE,
  KEY `idx_dept_id` (`dept_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=110 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='用户表';

-- ----------------------------
-- Records of sa_system_user
-- ----------------------------
BEGIN;
INSERT INTO `sa_system_user` (`id`, `username`, `password`, `realname`, `gender`, `avatar`, `email`, `phone`, `signed`, `dashboard`, `dept_id`, `is_super`, `status`, `remark`, `login_time`, `login_ip`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1, 'admin', '$2y$10$wnixh48uDnaW/6D9EygDd.OHJK0vQY/4nHaTjMKBCVDBP2NiTatqS', '祭道之上', '2', 'https://ui-avatars.com/api/?name=b8Admin', 'saiadmin@admin.com', '15888888888', 'SaiAdmin是兼具设计美学与高效开发的后台系统!', 'statistics', 1, 1, 1, NULL, '2026-05-29 16:08:26', '127.0.0.1', 1, 1, '2026-01-01 00:00:00', '2026-05-29 16:08:26', NULL);
INSERT INTO `sa_system_user` (`id`, `username`, `password`, `realname`, `gender`, `avatar`, `email`, `phone`, `signed`, `dashboard`, `dept_id`, `is_super`, `status`, `remark`, `login_time`, `login_ip`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (2, 'martin', '$2y$10$J3EkwRH8rNkveaanx1.j.ebRiBpnnVUGWa.i2MS3aNpb9ydAOolmm', '刘炽平', '2', 'https://ui-avatars.com/api/?name=b8Admin', 'martin@163.com', '15888888888', NULL, 'work', 1, 0, 1, '', NULL, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_user` (`id`, `username`, `password`, `realname`, `gender`, `avatar`, `email`, `phone`, `signed`, `dashboard`, `dept_id`, `is_super`, `status`, `remark`, `login_time`, `login_ip`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (3, 'allen', '$2y$10$H8d7riOjOiwPSopguEQ1fuKZz.fA0A54OvuzTqgJlbG1N3uOxEwM.', '张小龙', '', 'https://ui-avatars.com/api/?name=b8Admin', '', '15888888888', NULL, 'work', 10, 0, 1, '', NULL, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_user` (`id`, `username`, `password`, `realname`, `gender`, `avatar`, `email`, `phone`, `signed`, `dashboard`, `dept_id`, `is_super`, `status`, `remark`, `login_time`, `login_ip`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (4, 'mark', '$2y$10$sY/4StKVV.N/8Ock8J8kdeIOK4jS4tAUoYjkzvB8Tzy0fLh.wA2KS', '任宇昕', NULL, 'https://ui-avatars.com/api/?name=b8Admin', NULL, '15888888888', NULL, 'work', 11, 0, 1, NULL, NULL, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_user` (`id`, `username`, `password`, `realname`, `gender`, `avatar`, `email`, `phone`, `signed`, `dashboard`, `dept_id`, `is_super`, `status`, `remark`, `login_time`, `login_ip`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (5, 'dowson', '$2y$10$sY/4StKVV.N/8Ock8J8kdeIOK4jS4tAUoYjkzvB8Tzy0fLh.wA2KS', '汤道生', NULL, 'https://ui-avatars.com/api/?name=b8Admin', NULL, '15888888888', NULL, 'work', 12, 0, 1, NULL, NULL, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_user` (`id`, `username`, `password`, `realname`, `gender`, `avatar`, `email`, `phone`, `signed`, `dashboard`, `dept_id`, `is_super`, `status`, `remark`, `login_time`, `login_ip`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (10, 'timi_boss', '$2y$10$sY/4StKVV.N/8Ock8J8kdeIOK4jS4tAUoYjkzvB8Tzy0fLh.wA2KS', '姚晓光', NULL, 'https://ui-avatars.com/api/?name=b8Admin', '', '15888888888', NULL, 'work', 111, 0, 1, '', NULL, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_user` (`id`, `username`, `password`, `realname`, `gender`, `avatar`, `email`, `phone`, `signed`, `dashboard`, `dept_id`, `is_super`, `status`, `remark`, `login_time`, `login_ip`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (100, 'dev_wang', '$2y$10$sY/4StKVV.N/8Ock8J8kdeIOK4jS4tAUoYjkzvB8Tzy0fLh.wA2KS', '王程序员', NULL, 'https://ui-avatars.com/api/?name=b8Admin', NULL, '15888888888', NULL, 'work', 1111, 0, 1, NULL, NULL, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_system_user` (`id`, `username`, `password`, `realname`, `gender`, `avatar`, `email`, `phone`, `signed`, `dashboard`, `dept_id`, `is_super`, `status`, `remark`, `login_time`, `login_ip`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (101, 'dev_li', '$2y$10$sY/4StKVV.N/8Ock8J8kdeIOK4jS4tAUoYjkzvB8Tzy0fLh.wA2KS', '李策划', NULL, 'https://ui-avatars.com/api/?name=b8Admin', NULL, '15888888888', NULL, 'work', 1111, 0, 1, NULL, NULL, NULL, 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
COMMIT;

-- ----------------------------
-- Table structure for sa_system_user_post
-- ----------------------------
DROP TABLE IF EXISTS `sa_system_user_post`;
CREATE TABLE `sa_system_user_post` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` bigint unsigned NOT NULL COMMENT '用户主键',
  `post_id` bigint unsigned NOT NULL COMMENT '岗位主键',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_user_id` (`user_id`) USING BTREE,
  KEY `idx_post_id` (`post_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='用户与岗位关联表';

-- ----------------------------
-- Records of sa_system_user_post
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for sa_system_user_role
-- ----------------------------
DROP TABLE IF EXISTS `sa_system_user_role`;
CREATE TABLE `sa_system_user_role` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL,
  `role_id` bigint unsigned NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_role_id` (`role_id`) USING BTREE,
  KEY `idx_user_id` (`user_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=55 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='用户角色关联';

-- ----------------------------
-- Records of sa_system_user_role
-- ----------------------------
BEGIN;
INSERT INTO `sa_system_user_role` (`id`, `user_id`, `role_id`) VALUES (1, 1, 1);
COMMIT;

-- ----------------------------
-- Table structure for sa_tool_crontab
-- ----------------------------
DROP TABLE IF EXISTS `sa_tool_crontab`;
CREATE TABLE `sa_tool_crontab` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `name` varchar(100) DEFAULT NULL COMMENT '任务名称',
  `type` smallint DEFAULT '4' COMMENT '任务类型',
  `target` varchar(500) DEFAULT NULL COMMENT '调用任务字符串',
  `parameter` varchar(1000) DEFAULT NULL COMMENT '调用任务参数',
  `task_style` tinyint(1) DEFAULT NULL COMMENT '执行类型',
  `rule` varchar(32) DEFAULT NULL COMMENT '任务执行表达式',
  `singleton` smallint DEFAULT '1' COMMENT '是否单次执行 (1 是 2 不是)',
  `status` smallint DEFAULT '1' COMMENT '状态 (1正常 2停用)',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `created_by` int DEFAULT NULL COMMENT '创建者',
  `updated_by` int DEFAULT NULL COMMENT '更新者',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='定时任务信息表';

-- ----------------------------
-- Records of sa_tool_crontab
-- ----------------------------
BEGIN;
INSERT INTO `sa_tool_crontab` (`id`, `name`, `type`, `target`, `parameter`, `task_style`, `rule`, `singleton`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1, '访问官网', 1, 'https://saithink.top', '', 1, '0 0 8 * * *', 2, 1, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_tool_crontab` (`id`, `name`, `type`, `target`, `parameter`, `task_style`, `rule`, `singleton`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (2, '登录gitee', 2, 'https://gitee.com/check_user_login', '{\"user_login\": \"saiadmin\"}', 1, '0 0 10 * * *', 2, 1, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
INSERT INTO `sa_tool_crontab` (`id`, `name`, `type`, `target`, `parameter`, `task_style`, `rule`, `singleton`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (3, '定时执行任务', 3, '\\plugin\\saiadmin\\process\\Test', '{\"type\":\"1\"}', 5, '0 0 */12 * * *', 2, 1, '', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00', NULL);
COMMIT;

-- ----------------------------
-- Table structure for sa_tool_crontab_log
-- ----------------------------
DROP TABLE IF EXISTS `sa_tool_crontab_log`;
CREATE TABLE `sa_tool_crontab_log` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `crontab_id` int unsigned DEFAULT NULL COMMENT '任务ID',
  `name` varchar(255) DEFAULT NULL COMMENT '任务名称',
  `target` varchar(500) DEFAULT NULL COMMENT '任务调用目标字符串',
  `parameter` varchar(1000) DEFAULT NULL COMMENT '任务调用参数',
  `exception_info` varchar(2000) DEFAULT NULL COMMENT '异常信息',
  `status` smallint DEFAULT '1' COMMENT '执行状态 (1成功 2失败)',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='定时任务执行日志表';

-- ----------------------------
-- Records of sa_tool_crontab_log
-- ----------------------------
BEGIN;
INSERT INTO `sa_tool_crontab_log` (`id`, `crontab_id`, `name`, `target`, `parameter`, `exception_info`, `status`, `create_time`, `update_time`, `delete_time`) VALUES (1, 3, '定时执行任务', '\\plugin\\saiadmin\\process\\Test', '{\"type\":\"1\"}', NULL, 1, '2026-05-30 00:00:00', '2026-05-30 00:00:00', NULL);
INSERT INTO `sa_tool_crontab_log` (`id`, `crontab_id`, `name`, `target`, `parameter`, `exception_info`, `status`, `create_time`, `update_time`, `delete_time`) VALUES (2, 1, '访问官网', 'https://saithink.top', '', 'cURL error 28: Connection timed out after 5002 milliseconds (see https://curl.haxx.se/libcurl/c/libcurl-errors.html) for https://saithink.top', 2, '2026-05-30 08:00:06', '2026-05-30 08:00:06', NULL);
INSERT INTO `sa_tool_crontab_log` (`id`, `crontab_id`, `name`, `target`, `parameter`, `exception_info`, `status`, `create_time`, `update_time`, `delete_time`) VALUES (3, 2, '登录gitee', 'https://gitee.com/check_user_login', '{\"user_login\": \"saiadmin\"}', '{\"result\":1,\"failed_count\":1}', 1, '2026-05-30 10:00:01', '2026-05-30 10:00:01', NULL);
INSERT INTO `sa_tool_crontab_log` (`id`, `crontab_id`, `name`, `target`, `parameter`, `exception_info`, `status`, `create_time`, `update_time`, `delete_time`) VALUES (4, 3, '定时执行任务', '\\plugin\\saiadmin\\process\\Test', '{\"type\":\"1\"}', NULL, 1, '2026-05-30 12:00:00', '2026-05-30 12:00:00', NULL);
INSERT INTO `sa_tool_crontab_log` (`id`, `crontab_id`, `name`, `target`, `parameter`, `exception_info`, `status`, `create_time`, `update_time`, `delete_time`) VALUES (5, 3, '定时执行任务', '\\plugin\\saiadmin\\process\\Test', '{\"type\":\"1\"}', NULL, 1, '2026-05-31 00:00:00', '2026-05-31 00:00:00', NULL);
COMMIT;

-- ----------------------------
-- Table structure for sa_tool_generate_columns
-- ----------------------------
DROP TABLE IF EXISTS `sa_tool_generate_columns`;
CREATE TABLE `sa_tool_generate_columns` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `table_id` int unsigned DEFAULT NULL COMMENT '所属表ID',
  `column_name` varchar(200) DEFAULT NULL COMMENT '字段名称',
  `column_comment` varchar(255) DEFAULT NULL COMMENT '字段注释',
  `column_type` varchar(50) DEFAULT NULL COMMENT '字段类型',
  `default_value` varchar(50) DEFAULT NULL COMMENT '默认值',
  `is_pk` smallint DEFAULT '1' COMMENT '1 非主键 2 主键',
  `is_required` smallint DEFAULT '1' COMMENT '1 非必填 2 必填',
  `is_insert` smallint DEFAULT '1' COMMENT '1 非插入字段 2 插入字段',
  `is_edit` smallint DEFAULT '1' COMMENT '1 非编辑字段 2 编辑字段',
  `is_list` smallint DEFAULT '1' COMMENT '1 非列表显示字段 2 列表显示字段',
  `is_query` smallint DEFAULT '1' COMMENT '1 非查询字段 2 查询字段',
  `is_sort` smallint DEFAULT '1' COMMENT '1 非排序 2 排序',
  `query_type` varchar(100) DEFAULT 'eq' COMMENT '查询方式 eq 等于, neq 不等于, gt 大于, lt 小于, like 范围',
  `view_type` varchar(100) DEFAULT 'text' COMMENT '页面控件,text, textarea, password, select, checkbox, radio, date, upload, ma-upload(封装的上传控件)',
  `dict_type` varchar(200) DEFAULT NULL COMMENT '字典类型',
  `allow_roles` varchar(255) DEFAULT NULL COMMENT '允许查看该字段的角色',
  `options` varchar(1000) DEFAULT NULL COMMENT '字段其他设置',
  `sort` tinyint unsigned DEFAULT '0' COMMENT '排序',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `created_by` int DEFAULT NULL COMMENT '创建者',
  `updated_by` int DEFAULT NULL COMMENT '更新者',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='代码生成业务字段表';

-- ----------------------------
-- Records of sa_tool_generate_columns
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for sa_tool_generate_tables
-- ----------------------------
DROP TABLE IF EXISTS `sa_tool_generate_tables`;
CREATE TABLE `sa_tool_generate_tables` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `table_name` varchar(200) DEFAULT NULL COMMENT '表名称',
  `table_comment` varchar(500) DEFAULT NULL COMMENT '表注释',
  `stub` varchar(50) DEFAULT NULL COMMENT 'stub类型',
  `template` varchar(50) DEFAULT NULL COMMENT '模板名称',
  `namespace` varchar(255) DEFAULT NULL COMMENT '命名空间',
  `package_name` varchar(100) DEFAULT NULL COMMENT '控制器包名',
  `business_name` varchar(50) DEFAULT NULL COMMENT '业务名称',
  `class_name` varchar(50) DEFAULT NULL COMMENT '类名称',
  `menu_name` varchar(100) DEFAULT NULL COMMENT '生成菜单名',
  `belong_menu_id` int DEFAULT NULL COMMENT '所属菜单',
  `tpl_category` varchar(100) DEFAULT NULL COMMENT '生成类型,single 单表CRUD,tree 树表CRUD,parent_sub父子表CRUD',
  `generate_type` smallint DEFAULT '1' COMMENT '1 压缩包下载 2 生成到模块',
  `generate_path` varchar(100) DEFAULT 'saiadmin-artd' COMMENT '前端根目录',
  `generate_model` smallint DEFAULT '1' COMMENT '1 软删除 2 非软删除',
  `generate_menus` varchar(255) DEFAULT NULL COMMENT '生成菜单列表',
  `build_menu` smallint DEFAULT '1' COMMENT '是否构建菜单',
  `component_type` smallint DEFAULT '1' COMMENT '组件显示方式',
  `options` varchar(1500) DEFAULT NULL COMMENT '其他业务选项',
  `form_width` int DEFAULT '800' COMMENT '表单宽度',
  `is_full` tinyint(1) DEFAULT '1' COMMENT '是否全屏',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `source` varchar(255) DEFAULT NULL COMMENT '数据源',
  `created_by` int DEFAULT NULL COMMENT '创建者',
  `updated_by` int DEFAULT NULL COMMENT '更新者',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='代码生成业务表';

-- ----------------------------
-- Records of sa_tool_generate_tables
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for saiai_chat
-- ----------------------------
DROP TABLE IF EXISTS `saiai_chat`;
CREATE TABLE `saiai_chat` (
  `id` int NOT NULL AUTO_INCREMENT,
  `group_id` int DEFAULT NULL COMMENT '分组ID',
  `user_id` int NOT NULL DEFAULT '0' COMMENT '用户ID',
  `role` varchar(20) NOT NULL DEFAULT 'user' COMMENT '角色',
  `model` varchar(50) DEFAULT '' COMMENT '模型名称',
  `content` text COMMENT '消息内容',
  `tokens` int DEFAULT '0' COMMENT '消耗token数',
  `ip` varchar(50) DEFAULT '' COMMENT 'IP地址',
  `user_agent` varchar(255) DEFAULT '' COMMENT 'User Agent',
  `created_by` int DEFAULT NULL COMMENT '创建人',
  `updated_by` int DEFAULT NULL COMMENT '修改人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_user_id` (`user_id`) USING BTREE,
  KEY `idx_session_id` (`group_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='AI对话记录表';

-- ----------------------------
-- Records of saiai_chat
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for saiai_chat_group
-- ----------------------------
DROP TABLE IF EXISTS `saiai_chat_group`;
CREATE TABLE `saiai_chat_group` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL DEFAULT '0' COMMENT '用户ID',
  `title` varchar(255) DEFAULT '' COMMENT '会话标题',
  `is_top` tinyint DEFAULT '0' COMMENT '是否置顶',
  `created_by` int DEFAULT NULL COMMENT '创建者',
  `updated_by` int DEFAULT NULL COMMENT '更新者',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_user_id` (`user_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='AI对话分组表';

-- ----------------------------
-- Records of saiai_chat_group
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for saiai_config
-- ----------------------------
DROP TABLE IF EXISTS `saiai_config`;
CREATE TABLE `saiai_config` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL COMMENT '配置名称',
  `type` varchar(20) NOT NULL COMMENT '平台类型: gemini, openai, deepseek',
  `ai_url` varchar(255) NOT NULL COMMENT 'API URL',
  `ai_key` varchar(255) NOT NULL COMMENT 'API Key',
  `model` varchar(50) NOT NULL COMMENT '模型名称',
  `is_default` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否默认: 1是,0否',
  `status` tinyint(1) DEFAULT '1' COMMENT '状态',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `created_by` int DEFAULT NULL COMMENT '创建者',
  `updated_by` int DEFAULT NULL COMMENT '更新者',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='AI配置表';

-- ----------------------------
-- Records of saiai_config
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for saicode_column
-- ----------------------------
DROP TABLE IF EXISTS `saicode_column`;
CREATE TABLE `saicode_column` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `table_id` int unsigned DEFAULT NULL COMMENT '所属表ID',
  `column_name` varchar(200) DEFAULT NULL COMMENT '字段名称',
  `column_comment` varchar(255) DEFAULT NULL COMMENT '字段注释',
  `column_type` varchar(50) DEFAULT NULL COMMENT '字段类型',
  `column_width` int DEFAULT '0' COMMENT '列表宽度',
  `default_value` varchar(50) DEFAULT NULL COMMENT '默认值',
  `is_pk` smallint DEFAULT '1' COMMENT '1 非主键 2 主键',
  `is_required` smallint DEFAULT '1' COMMENT '1 非必填 2 必填',
  `is_insert` smallint DEFAULT '1' COMMENT '1 非插入字段 2 插入字段',
  `is_edit` smallint DEFAULT '1' COMMENT '1 非编辑字段 2 编辑字段',
  `is_list` smallint DEFAULT '1' COMMENT '1 非列表显示字段 2 列表显示字段',
  `is_query` smallint DEFAULT '1' COMMENT '1 非查询字段 2 查询字段',
  `is_sort` smallint DEFAULT '1' COMMENT '1 非排序 2 排序',
  `query_type` varchar(100) DEFAULT 'eq' COMMENT '查询方式',
  `view_type` varchar(100) DEFAULT 'input' COMMENT '页面控件',
  `dict_type` varchar(200) DEFAULT NULL COMMENT '字典类型',
  `options` text COMMENT '字段其他设置',
  `list_sort` smallint unsigned DEFAULT '0' COMMENT '列表排序',
  `span` smallint DEFAULT NULL COMMENT '布局',
  `form_sort` smallint unsigned DEFAULT '0' COMMENT '字段排序',
  `query_component` varchar(200) DEFAULT 'input' COMMENT '查询控件',
  `query_dict` varchar(200) DEFAULT NULL COMMENT '查询字典',
  `query_span` int DEFAULT '6' COMMENT '搜索栅格宽度',
  `query_sort` int DEFAULT '0' COMMENT '搜索排序',
  `query_options` text COMMENT '查询属性配置',
  `table_field` varchar(255) DEFAULT NULL COMMENT '列表名称',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `created_by` int DEFAULT NULL COMMENT '创建者',
  `updated_by` int DEFAULT NULL COMMENT '更新者',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='代码生成业务字段表';

-- ----------------------------
-- Records of saicode_column
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for saicode_table
-- ----------------------------
DROP TABLE IF EXISTS `saicode_table`;
CREATE TABLE `saicode_table` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `table_name` varchar(200) DEFAULT NULL COMMENT '表名称',
  `table_comment` varchar(500) DEFAULT NULL COMMENT '表注释',
  `stub` varchar(50) DEFAULT NULL COMMENT 'stub类型',
  `template` varchar(50) DEFAULT NULL COMMENT '模板名称',
  `namespace` varchar(255) DEFAULT NULL COMMENT '命名空间',
  `package_name` varchar(100) DEFAULT NULL COMMENT '控制器包名',
  `business_name` varchar(50) DEFAULT NULL COMMENT '业务名称',
  `class_name` varchar(50) DEFAULT NULL COMMENT '类名称',
  `menu_name` varchar(100) DEFAULT NULL COMMENT '生成菜单名',
  `belong_menu_id` int DEFAULT NULL COMMENT '所属菜单',
  `tpl_category` varchar(100) DEFAULT NULL COMMENT '生成类型',
  `generate_type` smallint DEFAULT '1' COMMENT '1 压缩包下载 2 生成到模块',
  `generate_model` smallint DEFAULT '1' COMMENT '1 软删除 2 非软删除',
  `generate_path` varchar(100) DEFAULT 'saiadmin-artd' COMMENT '前端根目录',
  `generate_menus` varchar(255) DEFAULT NULL COMMENT '生成菜单列表',
  `component_type` smallint DEFAULT '1' COMMENT '组件方式',
  `form_width` int DEFAULT '600' COMMENT '宽度',
  `is_full` smallint DEFAULT '1' COMMENT '是否全屏',
  `span` smallint DEFAULT NULL COMMENT '布局',
  `options` varchar(1500) DEFAULT NULL COMMENT '其他业务选项',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `source` varchar(255) DEFAULT NULL COMMENT '数据源',
  `created_by` int DEFAULT NULL COMMENT '创建者',
  `updated_by` int DEFAULT NULL COMMENT '更新者',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='低代码数据表';

-- ----------------------------
-- Records of saicode_table
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for saipay_order
-- ----------------------------
DROP TABLE IF EXISTS `saipay_order`;
CREATE TABLE `saipay_order` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '订单ID',
  `plugin` varchar(50) DEFAULT NULL COMMENT '插件平台',
  `order_no` varchar(50) NOT NULL DEFAULT '' COMMENT '订单号',
  `order_name` varchar(255) NOT NULL COMMENT '订单名称',
  `order_price` decimal(10,2) unsigned NOT NULL COMMENT '订单金额',
  `pay_price` decimal(10,2) unsigned DEFAULT NULL COMMENT '支付金额',
  `remark` varchar(255) DEFAULT '' COMMENT '备注留言',
  `pay_method` varchar(60) NOT NULL DEFAULT '' COMMENT '支付方式',
  `pay_type` varchar(60) DEFAULT NULL COMMENT '支付类型',
  `pay_status` tinyint unsigned DEFAULT '0' COMMENT '付款状态',
  `pay_time` datetime DEFAULT NULL COMMENT '付款时间',
  `trade_no` varchar(255) DEFAULT '0' COMMENT '第三方交易',
  `pay_url` varchar(1000) DEFAULT NULL COMMENT '支付链接',
  `pay_url_expire` datetime DEFAULT NULL COMMENT '过期时间',
  `member_id` int DEFAULT NULL COMMENT '关联用户',
  `order_id` int DEFAULT NULL COMMENT '关联订单',
  `created_by` int DEFAULT NULL COMMENT '创建者',
  `updated_by` int DEFAULT NULL COMMENT '更新者',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `unx_order_no` (`order_no`),
  KEY `idx_plugin` (`plugin`),
  KEY `idx_trade_no` (`trade_no`),
  KEY `idx_pay_time` (`pay_time`),
  KEY `idx_pay_method` (`pay_method`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='订单记录表';

-- ----------------------------
-- Records of saipay_order
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for saisms_config
-- ----------------------------
DROP TABLE IF EXISTS `saisms_config`;
CREATE TABLE `saisms_config` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '编号',
  `gateway` varchar(50) DEFAULT NULL COMMENT '网关标识',
  `config_name` varchar(50) DEFAULT NULL COMMENT '网关名称',
  `config` varchar(1000) DEFAULT NULL COMMENT '配置',
  `status` tinyint(1) DEFAULT '1' COMMENT '状态',
  `sort` smallint DEFAULT '100' COMMENT '排序',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `created_by` int DEFAULT NULL COMMENT '创建人',
  `updated_by` int DEFAULT NULL COMMENT '更新人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `unx_gateway` (`gateway`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='短信配置';

-- ----------------------------
-- Records of saisms_config
-- ----------------------------
BEGIN;
INSERT INTO `saisms_config` (`id`, `gateway`, `config_name`, `config`, `status`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (1, 'aliyun', '阿里云', '{\"access_key_id\":\"\",\"access_key_secret\":\"\"}', 1, 100, NULL, 1, 1, '2026-05-29 01:59:40', '2026-05-29 01:59:40', NULL);
INSERT INTO `saisms_config` (`id`, `gateway`, `config_name`, `config`, `status`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (2, 'qcloud', '腾讯云', '{\"sdk_app_id\":\"\",\"secret_id\":\"\"}', 1, 100, NULL, 1, 1, '2026-05-29 01:59:40', '2026-05-29 01:59:40', NULL);
INSERT INTO `saisms_config` (`id`, `gateway`, `config_name`, `config`, `status`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (3, 'qiniu', '七牛云', '{\"secret_key\":\"\",\"access_key\":\"\"}', 1, 200, NULL, 1, 1, '2026-05-29 01:59:40', '2026-05-29 01:59:40', NULL);
INSERT INTO `saisms_config` (`id`, `gateway`, `config_name`, `config`, `status`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (4, 'link', '凌凯短信', '{\"CorpID\":\"\",\"Pwd\":\"\"}', 1, 99, NULL, 1, 1, '2026-05-29 01:59:40', '2026-05-29 01:59:40', NULL);
INSERT INTO `saisms_config` (`id`, `gateway`, `config_name`, `config`, `status`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`) VALUES (5, 'baidu', '百度云', '{\"ak\":\"\",\"sk\":\"\",\"invoke_id\":\"\",\"domain\":\"\"}', 1, 100, NULL, 1, 1, '2026-05-29 01:59:40', '2026-05-29 01:59:40', NULL);
COMMIT;

-- ----------------------------
-- Table structure for saisms_record
-- ----------------------------
DROP TABLE IF EXISTS `saisms_record`;
CREATE TABLE `saisms_record` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '编号',
  `gateway` varchar(50) DEFAULT NULL COMMENT '网关',
  `mobile` varchar(20) DEFAULT NULL COMMENT '手机号码',
  `code` varchar(20) DEFAULT NULL COMMENT '验证码',
  `content` varchar(500) DEFAULT NULL COMMENT '短信内容',
  `status` varchar(20) DEFAULT NULL COMMENT '发送状态',
  `response` varchar(500) DEFAULT NULL COMMENT '返回结果',
  `is_verify` tinyint(1) DEFAULT '2' COMMENT '是否验证',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='短信记录';

-- ----------------------------
-- Records of saisms_record
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for saisms_tag
-- ----------------------------
DROP TABLE IF EXISTS `saisms_tag`;
CREATE TABLE `saisms_tag` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '编号',
  `tag_name` varchar(50) DEFAULT NULL COMMENT '标签名称',
  `gateway` varchar(50) DEFAULT NULL COMMENT '网关标识',
  `sms_type` tinyint(1) DEFAULT '1' COMMENT '短信类型',
  `template_id` varchar(255) DEFAULT NULL COMMENT '模板编号',
  `content` varchar(255) DEFAULT NULL COMMENT '短信内容',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `created_by` int DEFAULT NULL COMMENT '创建人',
  `updated_by` int DEFAULT NULL COMMENT '更新人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='短信标签';

-- ----------------------------
-- Records of saisms_tag
-- ----------------------------
BEGIN;
COMMIT;

SET FOREIGN_KEY_CHECKS = 1;
