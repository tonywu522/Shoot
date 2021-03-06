//
//  User.h
//  Shoot
//
//  Created by LV on 2/15/15.
//  Copyright (c) 2015 Shoot. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <MapKit/MapKit.h>

#define USER_TYPE_USER @"User"

@class Message, Shoot, User, UserTagShoot, Comment;

@interface User : NSManagedObject

@property (nonatomic, retain) NSNumber * userID;
@property (nonatomic, retain) NSDate * time;
@property (nonatomic, retain) NSNumber * shouldBeDeleted;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * password;
@property (nonatomic, retain) NSNumber * follower_count;
@property (nonatomic, retain) NSNumber * following_count;
@property (nonatomic, retain) NSNumber * have_count;
@property (nonatomic, retain) NSNumber * want_count;
@property (nonatomic, retain) NSNumber * has_avatar;
@property (nonatomic, retain) NSNumber * has_bg_image;
@property (nonatomic, retain) NSNumber * relationship_with_currentUser;
@property (nonatomic, retain) NSString * user_type;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSSet *followers;
@property (nonatomic, retain) NSSet *followings;
@property (nonatomic, retain) NSSet *messages;
@property (nonatomic, retain) NSSet *shoot_tags;
@property (nonatomic, retain) NSSet *shoots;
@property (nonatomic, retain) NSSet *comments;

+ (NSString *) getFormatedAddressWithPlaceMark:(CLPlacemark *)placeMark;
/*
 * return invalid reason otherwise return nil
 */
+ (NSString *)validateUsername:(NSString *)username;
/*
 * return invalid reason otherwise return nil
 */
+ (NSString *)validatePassword:(NSString *)password;
+ (BOOL)isEmailValid:(NSString*)email;

@end

@interface User (CoreDataGeneratedAccessors)

- (void)addFollowersObject:(User *)value;
- (void)removeFollowersObject:(User *)value;
- (void)addFollowers:(NSSet *)values;
- (void)removeFollowers:(NSSet *)values;

- (void)addFollowingsObject:(User *)value;
- (void)removeFollowingsObject:(User *)value;
- (void)addFollowings:(NSSet *)values;
- (void)removeFollowings:(NSSet *)values;

- (void)addMessagesObject:(Message *)value;
- (void)removeMessagesObject:(Message *)value;
- (void)addMessages:(NSSet *)values;
- (void)removeMessages:(NSSet *)values;

- (void)addShoot_tagsObject:(UserTagShoot *)value;
- (void)removeShoot_tagsObject:(UserTagShoot *)value;
- (void)addShoot_tags:(NSSet *)values;
- (void)removeShoot_tags:(NSSet *)values;

- (void)addShootsObject:(Shoot *)value;
- (void)removeShootsObject:(Shoot *)value;
- (void)addShoots:(NSSet *)values;
- (void)removeShoots:(NSSet *)values;

- (void)addCommentsObject:(Shoot *)value;
- (void)removeCommentsObject:(Shoot *)value;
- (void)addComments:(NSSet *)values;
- (void)removeComments:(NSSet *)values;

@end
