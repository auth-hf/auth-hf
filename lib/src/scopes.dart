final AccessScope profile = new AccessScope(
  '/user',
  'View your profile',
  'user',
);

final AccessScope userInfo = new AccessScope(
  '/user/:id',
  'View information about any user',
  new RegExp(r'user/([0-9]+)'),
);

final AccessScope multipleUsersInfo = new AccessScope(
  '/users/:ids',
  'View information about multiple users',
  new RegExp(r'users/([0-9]+)'),
);

final AccessScope categoryInfo = new AccessScope(
  '/category/:id',
  'View information about a forum category',
  new RegExp(r'category/([0-9]+)'),
);

final AccessScope forumInfo = new AccessScope(
  '/forum/:id',
  'View information about a forum',
  new RegExp(r'forum/([0-9]+)'),
);

final AccessScope threadInfo = new AccessScope(
  '/thread/:id',
  'View information about a forum thread',
  new RegExp(r'thread/([0-9]+)'),
);

final AccessScope postInfo = new AccessScope(
  '/post/:id',
  'View information about a forum post',
  new RegExp(r'post/([0-9]+)'),
);

final AccessScope privateMessage = new AccessScope(
  '/pm/:id',
  'Read the contents of private messages',
  new RegExp(r'pm/([0-9]+)'),
);

final AccessScope pmBox = new AccessScope(
  '/pmbox/:id',
  'List PMs in a PM box',
  new RegExp(r'pmbox/([0-9]+)'),
);

final AccessScope inbox = new AccessScope(
  '/inbox',
  'List PMs in your inbox',
  new RegExp(r'inbox'),
);

final AccessScope groupInfo = new AccessScope(
  '/group/:info',
  'View information about usergroups',
  new RegExp(r'group/([0-9]+)'),
);

final List<AccessScope> all = [
  profile,
  userInfo,
  multipleUsersInfo,
  categoryInfo,
  forumInfo,
  threadInfo,
  postInfo,
  privateMessage,
  pmBox,
  inbox,
  groupInfo,
];

class AccessScope {
  final String stub, description;
  final Pattern matcher;

  const AccessScope(this.stub, this.description, this.matcher);
}
