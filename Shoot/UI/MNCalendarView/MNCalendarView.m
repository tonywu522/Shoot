//
//  MNCalendarView.m
//  MNCalendarView
//
//  Created by Min Kim on 7/23/13.
//  Copyright (c) 2013 min. All rights reserved.
//

#import "MNCalendarView.h"
#import "MNCalendarViewLayout.h"
#import "MNCalendarViewDayCell.h"
#import "MNCalendarViewWeekdayCell.h"
#import "MNCalendarHeaderView.h"
#import "MNFastDateEnumeration.h"
#import "NSDate+MNAdditions.h"
#import "ColorDefinition.h"
#import "UserTagShootCollectionViewCell.h"

@interface MNCalendarView() <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic,strong,readwrite) UICollectionView *collectionView;
@property (nonatomic,strong,readwrite) UICollectionViewFlowLayout *layout;

@property (nonatomic,strong,readwrite) NSMutableArray *monthDates;
@property (nonatomic,strong,readwrite) NSArray *weekdaySymbols;
@property (nonatomic,assign,readwrite) NSUInteger daysInWeek;

@property (nonatomic, retain) NSMutableSet *highlightedDateSet;

@property(nonatomic,strong,readwrite) NSDateFormatter *monthFormatter;

@property (retain, nonatomic) UIViewController *parentController;

- (NSDate *)firstVisibleDateOfMonth:(NSDate *)date;
- (NSDate *)lastVisibleDateOfMonth:(NSDate *)date;

- (BOOL)dateEnabled:(NSDate *)date;
- (BOOL)canSelectItemAtIndexPath:(NSIndexPath *)indexPath;

- (void)applyConstraints;

@end

@implementation MNCalendarView

- (void)commonInit {
    
    self.highlightedDateSet = [NSMutableSet new];
    
    self.calendar   = NSCalendar.currentCalendar;
    self.fromDate   = [NSDate.date mn_beginningOfDay:self.calendar];
    self.toDate     = [self.fromDate dateByAddingTimeInterval:MN_YEAR * 4];
    self.daysInWeek = 7;
    
    self.headerViewClass  = MNCalendarHeaderView.class;
    self.weekdayCellClass = MNCalendarViewWeekdayCell.class;
    self.dayCellClass     = MNCalendarViewDayCell.class;
    self.imageCellClass = UserTagShootCollectionViewCell.class;
    
    _separatorColor = [UIColor colorWithRed:.85f green:.85f blue:.85f alpha:1.f];
    
    [self addSubview:self.collectionView];
    [self applyConstraints];
    [self reloadData];
}

- (id)initWithFrame:(CGRect)frame withParentController:(UIViewController *)parentController {
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
        self.parentController = parentController;
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder: aDecoder];
    if ( self ) {
        [self commonInit];
    }
    
    return self;
}

- (void) setHighlightedDates:(NSArray *)highlightedDates
{
    [self.highlightedDateSet removeAllObjects];
    NSDate *minDate = nil;
    for (NSDate *date in highlightedDates) {
        if (minDate == nil || [minDate compare:date] == NSOrderedDescending)  {
            minDate = date;
        }
        NSDateComponents *components =
        [self.calendar components:NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear|NSCalendarUnitWeekday
                         fromDate:date];
        [self.highlightedDateSet addObject:[self.calendar dateFromComponents:components]];
    }
    if (minDate) {
        NSDateComponents *components =
        [self.calendar components:NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear|NSCalendarUnitWeekday
                         fromDate:[NSDate new]];
        components.month -= 1;
        NSDate *twoMonthAgo = [self.calendar dateFromComponents:components];
        if ([minDate compare:twoMonthAgo] == NSOrderedDescending)  {
            self.fromDate = twoMonthAgo;
        } else {
            self.fromDate = minDate;
        }
        self.toDate = [NSDate new];
    }
}

- (UICollectionView *)collectionView {
    if (nil == _collectionView) {
        MNCalendarViewLayout *layout = [[MNCalendarViewLayout alloc] init];
        
        _collectionView =
        [[UICollectionView alloc] initWithFrame:CGRectZero
                           collectionViewLayout:layout];
        _collectionView.backgroundColor = [UIColor colorWithRed:.96f green:.96f blue:.96f alpha:1.f];
        _collectionView.translatesAutoresizingMaskIntoConstraints = NO;
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        
        [self registerUICollectionViewClasses];
    }
    return _collectionView;
}

- (void)setSeparatorColor:(UIColor *)separatorColor {
    _separatorColor = separatorColor;
}

- (void)setCalendar:(NSCalendar *)calendar {
    _calendar = calendar;
    
    self.monthFormatter = [[NSDateFormatter alloc] init];
    self.monthFormatter.calendar = calendar;
    [self.monthFormatter setDateFormat:@"MMMM yyyy"];
}

- (void)setSelectedDate:(NSDate *)selectedDate {
    _selectedDate = [selectedDate mn_beginningOfDay:self.calendar];
}

- (void)reloadData {
    self.selectedDate = nil;
    NSMutableArray *monthDates = @[].mutableCopy;
    MNFastDateEnumeration *enumeration =
    [[MNFastDateEnumeration alloc] initWithFromDate:[self.fromDate mn_firstDateOfMonth:self.calendar]
                                             toDate:[self.toDate mn_firstDateOfMonth:self.calendar]
                                           calendar:self.calendar
                                               unit:NSCalendarUnitMonth];
    for (NSDate *date in enumeration) {
        [monthDates addObject:date];
    }
    self.monthDates = @[].mutableCopy;
    for (NSDate *date in [monthDates reverseObjectEnumerator]){
        [self.monthDates addObject:date];
    }
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.calendar = self.calendar;
    
    self.weekdaySymbols = formatter.shortWeekdaySymbols;
    
    [self.collectionView reloadData];
}

- (void)registerUICollectionViewClasses {
    [_collectionView registerClass:self.dayCellClass
        forCellWithReuseIdentifier:MNCalendarViewDayCellIdentifier];
    
    [_collectionView registerClass:self.imageCellClass forCellWithReuseIdentifier:UserTagShootCollectionViewCellIdentifier];
    
    [_collectionView registerClass:self.weekdayCellClass
        forCellWithReuseIdentifier:MNCalendarViewWeekdayCellIdentifier];
    
    [_collectionView registerClass:self.headerViewClass
        forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
               withReuseIdentifier:MNCalendarHeaderViewIdentifier];
}

- (NSDate *)firstVisibleDateOfMonth:(NSDate *)date {
    date = [date mn_firstDateOfMonth:self.calendar];
    
    NSDateComponents *components =
    [self.calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitWeekday
                     fromDate:date];
    
    return
    [[date mn_dateWithDay:-((components.weekday - 1) % self.daysInWeek) calendar:self.calendar] dateByAddingTimeInterval:MN_DAY];
}

- (NSDate *)lastVisibleDateOfMonth:(NSDate *)date {
    date = [date mn_lastDateOfMonth:self.calendar];
    
    NSDateComponents *components =
    [self.calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitWeekday
                     fromDate:date];
    
    return
    [date mn_dateWithDay:components.day + (self.daysInWeek - 1) - ((components.weekday - 1) % self.daysInWeek)
                calendar:self.calendar];
}

- (void)applyConstraints {
    NSDictionary *views = @{@"collectionView" : self.collectionView};
    [self addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[collectionView]|"
                                             options:0
                                             metrics:nil
                                               views:views]];
    
    [self addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[collectionView]|"
                                             options:0
                                             metrics:nil
                                               views:views]
     ];
}

- (BOOL)dateEnabled:(NSDate *)date {
    if (self.delegate && [self.delegate respondsToSelector:@selector(calendarView:shouldSelectDate:)]) {
        return [self.delegate calendarView:self shouldSelectDate:date];
    }
    return YES;
}

- (BOOL)canSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSDate *monthDate = self.monthDates[indexPath.section];
    
    if (self.selectedDate && [self.calendar component:NSCalendarUnitMonth
                                             fromDate:monthDate] == [self.calendar component:NSCalendarUnitMonth fromDate:self.selectedDate]) {
        if ([self isImageDisplayCell:indexPath]) {
            return false;
        }
    }
    
    MNCalendarViewCell *cell = (MNCalendarViewCell *)[self collectionView:self.collectionView cellForItemAtIndexPath:indexPath];
    
    BOOL enabled = cell.enabled;
    
    if ([cell isKindOfClass:MNCalendarViewDayCell.class] && enabled) {
        MNCalendarViewDayCell *dayCell = (MNCalendarViewDayCell *)cell;
        
        enabled = [self dateEnabled:dayCell.date];
    }
    return enabled;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return self.monthDates.count;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath {
    MNCalendarHeaderView *headerView =
    [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                       withReuseIdentifier:MNCalendarHeaderViewIdentifier
                                              forIndexPath:indexPath];
    
    headerView.backgroundColor = self.collectionView.backgroundColor;
    headerView.titleLabel.text = [self.monthFormatter stringFromDate:self.monthDates[indexPath.section]];
    
    return headerView;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSDate *monthDate = self.monthDates[section];
    
    NSDateComponents *components =
    [self.calendar components:NSCalendarUnitDay
                     fromDate:[self firstVisibleDateOfMonth:monthDate]
                       toDate:[self lastVisibleDateOfMonth:monthDate]
                      options:0];
    if (self.selectedDate && [self.calendar component:NSCalendarUnitMonth
                                             fromDate:monthDate] == [self.calendar component:NSCalendarUnitMonth fromDate:self.selectedDate]) {
        return self.daysInWeek + components.day + 2;
    } else {
        return self.daysInWeek + components.day + 1;
    }
    
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.item < self.daysInWeek) {
        MNCalendarViewWeekdayCell *cell =
        [collectionView dequeueReusableCellWithReuseIdentifier:MNCalendarViewWeekdayCellIdentifier
                                                  forIndexPath:indexPath];
        
        cell.backgroundColor = self.collectionView.backgroundColor;
        cell.titleLabel.text = self.weekdaySymbols[indexPath.item];
        cell.separatorColor = self.separatorColor;
        return cell;
    }
    
    NSDate *monthDate = self.monthDates[indexPath.section];
    if (self.selectedDate && [self.calendar component:NSCalendarUnitMonth
                                             fromDate:self.monthDates[indexPath.section]] == [self.calendar component:NSCalendarUnitMonth fromDate:self.selectedDate]) {
        if ([self isImageDisplayCell:indexPath]) {
            UserTagShootCollectionViewCell *cell = (UserTagShootCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:UserTagShootCollectionViewCellIdentifier forIndexPath:indexPath];
            if (self.dataSource && [self.dataSource respondsToSelector:@selector(userShootTagsPredicateFrom:to:)]) {
                NSDateComponents *components =
                [self.calendar components:NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear
                                 fromDate:self.selectedDate];
                components.day += 1;
                NSPredicate *predicate = [self.dataSource userShootTagsPredicateFrom:self.selectedDate to:[self.calendar dateFromComponents:components]];
                [cell decorateWithUserTagShootsPredicate:predicate parentController:self.parentController];
            }
            return cell;
        }
    }
    NSDate *firstDateInMonth = [self firstVisibleDateOfMonth:monthDate];
    
    NSUInteger day = indexPath.item - self.daysInWeek;
    
    NSDateComponents *components =
    [self.calendar components:NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear
                     fromDate:firstDateInMonth];
    components.day += day;
    
    NSDate *date = [self.calendar dateFromComponents:components];
    if (self.selectedDate && [self.calendar component:NSCalendarUnitMonth
                                             fromDate:monthDate] == [self.calendar component:NSCalendarUnitMonth fromDate:self.selectedDate]) {
        if ([self getImageDisplayDate] < date) {
            components.day--;
            date = [self.calendar dateFromComponents:components];
        } else if ([self getImageDisplayDate] == date) {
            date = self.selectedDate;
        }
    }
    MNCalendarViewDayCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:MNCalendarViewDayCellIdentifier forIndexPath:indexPath];
    cell.separatorColor = self.separatorColor;
    [cell setDate:date
            month:monthDate
         calendar:self.calendar];
    
    
    if (cell.enabled) {
        [cell setEnabled:[self dateEnabled:date]];
    }
    BOOL hasContent = [self.highlightedDateSet containsObject:[self getEffectiveDateFromIndexPath:indexPath]];
    if (hasContent) {
        cell.imageView.backgroundColor = [ColorDefinition lightRed];
        cell.titleLabel.textColor = [UIColor whiteColor];
    } else {
        cell.imageView.backgroundColor = [UIColor clearColor];
    }
    if (self.selectedDate && cell.enabled) {
        [cell setSelected:[date isEqualToDate:self.selectedDate]];
    }
    
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self canSelectItemAtIndexPath:indexPath];
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self canSelectItemAtIndexPath:indexPath];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    BOOL hasDataSource = self.dataSource && [self.dataSource respondsToSelector:@selector(userShootTagsPredicateFrom:to:)];
    if (!hasDataSource) {
        return;
    }
    
    MNCalendarViewCell *cell = (MNCalendarViewCell *)[self collectionView:collectionView cellForItemAtIndexPath:indexPath];
    
    if ([cell isKindOfClass:MNCalendarViewDayCell.class] && cell.enabled) {
        BOOL hasContent = [self.highlightedDateSet containsObject:[self getEffectiveDateFromIndexPath:indexPath]];
        
        if (hasContent) {
            MNCalendarViewDayCell *dayCell = (MNCalendarViewDayCell *)cell;
            self.selectedDate = dayCell.date;
            
            if ([self.delegate respondsToSelector:@selector(calendarView:didSelectDate:)]) {
                [self.delegate calendarView:self didSelectDate:dayCell.date];
            }
            
        } else {
            self.selectedDate = nil;
        }
        [self.collectionView reloadData];
    }
    
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
        [self.delegate scrollViewDidScroll:scrollView];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.selectedDate && [self.calendar component:NSCalendarUnitMonth
                                             fromDate:self.monthDates[indexPath.section]] == [self.calendar component:NSCalendarUnitMonth fromDate:self.selectedDate]) {
        if ([self isImageDisplayCell:indexPath])
        {
            return CGSizeMake(self.frame.size.width, self.frame.size.width * 3.0 / 4.0);
        }
    }
    CGFloat width      = self.bounds.size.width;
    CGFloat itemWidth  = roundf(width / self.daysInWeek);
    CGFloat itemHeight = indexPath.item < self.daysInWeek ? 30.f : itemWidth;
    
    NSUInteger weekday = indexPath.item % self.daysInWeek;
    
    if (weekday == self.daysInWeek - 1) {
        itemWidth = width - (itemWidth * (self.daysInWeek - 1));
    }
    
    return CGSizeMake(itemWidth, itemHeight);
}

- (NSDate *) getImageDisplayDate {
    NSDateComponents *components =
    [self.calendar components:NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear|NSCalendarUnitWeekday
                     fromDate:self.selectedDate];
    if (components.weekday == 7) {
        components.day += 1;
    } else {
        components.day += (7 - components.weekday % 7 + 1);
    }
    return [self.calendar dateFromComponents:components];
}

- (BOOL) isImageDisplayCell:(NSIndexPath *)indexPath
{
    if (!self.selectedDate) {
        return false;
    }
    NSDate *monthDate = self.monthDates[indexPath.section];
    
    NSDate *firstDateInMonth = [self firstVisibleDateOfMonth:monthDate];
    
    NSUInteger day = indexPath.item - self.daysInWeek;
    
    NSDateComponents *components =
    [self.calendar components:NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear|NSCalendarUnitWeekday
                     fromDate:firstDateInMonth];
    components.day += day;
    
    return [self getImageDisplayDate] == [self.calendar dateFromComponents:components];
}

- (NSDate *) getEffectiveDateFromIndexPath:(NSIndexPath *)indexPath
{
    NSDate *monthDate = self.monthDates[indexPath.section];
    
    NSDate *firstDateInMonth = [self firstVisibleDateOfMonth:monthDate];
    
    NSUInteger day = indexPath.item - self.daysInWeek;
    
    NSDateComponents *components =
    [self.calendar components:NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear|NSCalendarUnitWeekday
                     fromDate:firstDateInMonth];
    components.day += day;
    NSDate *date = [self.calendar dateFromComponents:components];
    if (self.selectedDate && [self.calendar component:NSCalendarUnitMonth
                                             fromDate:monthDate] == [self.calendar component:NSCalendarUnitMonth fromDate:self.selectedDate]) {
        if ([self getImageDisplayDate] < date) {
            components.day--;
            date = [self.calendar dateFromComponents:components];
        } else if ([self getImageDisplayDate] == date) {
            date = self.selectedDate;
        }
    }
    
    return date;
}

@end
