//
//  ViewController.m
//  photosPicker
//
//  Created by 斌哥哥 on 2019/8/5.
//  Copyright © 2019 斌哥哥. All rights reserved.
//

#import "ViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "YBImageBrowser.h"
#import <Photos/Photos.h>
#import "Masonry.h"
#import "UIView+Toast.h"
#import "HobbiesCollectionViewCell.h"
#import "TZImagePickerController.h"
#import "YJVideoController.h"
#import "VideoPlayViewController.h"

@interface ViewController ()<UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout,UINavigationControllerDelegate,UIImagePickerControllerDelegate,YBImageBrowserDataSource,UIGestureRecognizerDelegate,TZImagePickerControllerDelegate>
{
    UICollectionView *myCollectionView;             //相册瀑布流
    NSMutableArray *imageArray;                     //图片数组
    NSMutableArray *selectArray;                    //图片选择数组
    NSMutableArray *phArray;                        //媒体数据数组
    NSInteger nums;                                 //最大可选择的照片数量
    NSInteger  IorV;                                //视频还是照片 -1:未选择  0:照片   1:视频
    UIView *bottomV;                                //相册所在的父视图
    UIView *toolView;                               //相册上方的工具视图（可自定义）
    UISwipeGestureRecognizer * recognizerUp;        //上滑手势
    UISwipeGestureRecognizer * recognizerDown;      //下拉手势
    BOOL isTop;                                     //是否滑动到顶部
    BOOL UPorDown;                                  //是否是在全屏状态
    NSInteger page;                                 //页码
    BOOL ready;                                     //是否准备好再次刷新
}
@property(nonatomic,strong) UIImagePickerController *imagePicker;
@end

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    [self initUI];
    [self checkPermissions];
}

#pragma mark -相册权限相关处理
/**
 检查是否开始了相册权限
 */
-(void)checkPermissions
{
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status == PHAuthorizationStatusAuthorized) {
            dispatch_main_async_safe(^{
                [self loadImageArray];
            });
        }else{
            //未获取相册权限
            [self showAlrtToSetting];
        }
    }];
}

/**
 检测到未开启相册权限之后的提醒
 */
-(void) showAlrtToSetting
{
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"开启相册权限" message:@"打开相册权限，上传您喜欢的图片" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:@"再看看" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    UIAlertAction * setAction = [UIAlertAction actionWithTitle:@"打开" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
                                 {
                                     NSURL * url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                         if ([[UIApplication sharedApplication] canOpenURL:url])
                                         {
                                             [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
                                                 dispatch_main_async_safe(^{
                                                     [self loadImageArray];
                                                 });
                                             }];
                                         }
                                     });
                                 }];
    [alert addAction:cancelAction];
    [alert addAction:setAction];
    [self presentViewController:alert animated:YES completion:nil];
}


/**
 初始化视图
 */
-(void)initUI
{
    self.view.backgroundColor = [UIColor lightGrayColor];
    nums = 0;
    IorV = -1;
    ready = YES;
    isTop = NO;
    page = 0;
    
    toolView = [[UIView alloc] initWithFrame:CGRectMake(0, HEIGHT-221-kSafeAreaBottomHeight-44, WIDTH, 44)];
    toolView.backgroundColor = [UIColor whiteColor];
    toolView.tag = 88;
    [self.view addSubview:toolView];
    
    bottomV = [[UIView alloc] init];
    [self.view addSubview:bottomV];
    [bottomV mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(toolView.mas_bottom);
        make.height.mas_equalTo(HEIGHT+221+kSafeAreaBottomHeight);
    }];
    
    //创建一个layout布局类
    UICollectionViewFlowLayout * layout = [[UICollectionViewFlowLayout alloc]init];
    //设置布局方向为垂直流布局
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    //设置每个item的大小为100*100
    layout.itemSize = CGSizeMake(WIDTH/4-1, WIDTH/4-1);
    //创建collectionView 通过一个布局策略layout来创建
    
    myCollectionView = [[UICollectionView alloc]initWithFrame:CGRectMake(0, 0, WIDTH, 221+kSafeAreaBottomHeight) collectionViewLayout:layout];
    myCollectionView.delegate = self;
    myCollectionView.dataSource = self;
    myCollectionView.scrollEnabled = YES;
    myCollectionView.bounces = NO;
    myCollectionView.backgroundColor = [UIColor blackColor];
    //注册Cell
    [myCollectionView registerNib:[UINib nibWithNibName:@"HobbiesCollectionViewCell" bundle: [NSBundle mainBundle]] forCellWithReuseIdentifier:@"HobbiesCollectionViewCell"];
    [bottomV addSubview:myCollectionView];

    recognizerUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFrom:)];
    recognizerUp.direction = UISwipeGestureRecognizerDirectionUp;
    recognizerUp.delegate = self;
    [self.view addGestureRecognizer:recognizerUp];
    
    recognizerDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFrom:)];
    recognizerDown.direction = UISwipeGestureRecognizerDirectionDown;
    recognizerDown.delegate = self;
    [self.view addGestureRecognizer:recognizerDown];
    
}

/**
 加载本地照片和视频数据
 */
-(void)loadImageArray
{
    [self.view makeToastActivity:CENTER];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // 处理耗时操作的代码块
        phArray = [NSMutableArray array];
        imageArray = [NSMutableArray array];
        PHFetchOptions *options = [[PHFetchOptions alloc] init];
        options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
        PHFetchResult *assetsFetchResults = [PHAsset fetchAssetsWithOptions:options];
        for (PHAsset *asset in assetsFetchResults)
        {
            //判断本地媒体数据是照片类型和视频类型，就加入到phArray数组中
            if (asset.mediaType == PHAssetMediaTypeImage || asset.mediaType == PHAssetMediaTypeVideo)
            {
                [phArray addObject:asset];
            }
        }
        phArray=(NSMutableArray *)[[phArray reverseObjectEnumerator] allObjects];  //数组倒序排列
        //加载前两百条数据（防止加载耗时过长）
        NSInteger counts = phArray.count;
        if(counts>200)
        {
            counts = 200;
        }
        for(int i=0;i<counts;i++)
        {
            PHAsset *asset = [phArray objectAtIndex:i];
            PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
            /** resizeMode：对请求的图像怎样缩放。有三种选择：None，默认加载方式；Fast，尽快地提供接近或稍微大于要求的尺寸；Exact，精准提供要求的尺寸。 deliveryMode：图像质量。有三种值：Opportunistic，在速度与质量中均衡；HighQualityFormat，不管花费多长时间，提供高质量图像；FastFormat，以最快速度提供好的质量。
             这个属性只有在 synchronous 为 true 时有效。
             */
            option.resizeMode = PHImageRequestOptionsResizeModeFast;//控制照片尺寸
            option.deliveryMode = 1;//控制照片质量
            option.synchronous = YES;
            option.networkAccessAllowed = YES;
            //param：targetSize 即你想要的图片尺寸，若想要原尺寸则可输入PHImageManagerMaximumSize
            [[PHCachingImageManager defaultManager] requestImageForAsset:asset targetSize:CGSizeMake(WIDTH/4, HEIGHT/4) contentMode:PHImageContentModeAspectFit options:option resultHandler:^(UIImage * _Nullable image, NSDictionary * _Nullable info) {
                NSString *types = @"0";  //0:照片 1:视频
                if(asset.mediaType == PHAssetMediaTypeImage)
                {
                    types = @"0";
                }
                else
                {
                    types = @"1";
                }
                NSDictionary *dic = @{@"image":image,@"type":types,@"times":@"0"};
                [imageArray addObject:dic];
            }];
        }
        
        //初始化是否选择的数组
        selectArray = [NSMutableArray array];
        for(int i=0;i<imageArray.count;i++)
        {
            [selectArray addObject:@"0"];
        }
        //通知主线程刷新
        dispatch_async(dispatch_get_main_queue(), ^{
            //回调或者说是通知主线程刷新
            [myCollectionView reloadData];
            [self.view hideToastActivity];
        });
    });
}

/**
 下拉加载下一页（200条）的数据
 */
-(void)footerClick
{
    if(phArray.count<200)
    {
        return;
    }
    ready = NO;
    NSInteger counts = phArray.count;
    NSInteger nowCounts = 200 + page*200;
    if(nowCounts < counts)
    {
        if(nowCounts < counts - 200)
        {
            counts = nowCounts + 200;
        }
    }
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // 处理耗时操作的代码块
        for(NSInteger i=nowCounts;i<counts;i++)
        {
            PHAsset *asset = [phArray objectAtIndex:i];
            PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
            /** resizeMode：对请求的图像怎样缩放。有三种选择：None，默认加载方式；Fast，尽快地提供接近或稍微大于要求的尺寸；Exact，精准提供要求的尺寸。 deliveryMode：图像质量。有三种值：Opportunistic，在速度与质量中均衡；HighQualityFormat，不管花费多长时间，提供高质量图像；FastFormat，以最快速度提供好的质量。
             这个属性只有在 synchronous 为 true 时有效。
             */
            option.resizeMode = PHImageRequestOptionsResizeModeFast;//控制照片尺寸
            option.deliveryMode = 1;//控制照片质量
            option.synchronous = YES;
            option.networkAccessAllowed = YES;
            //param：targetSize 即你想要的图片尺寸，若想要原尺寸则可输入PHImageManagerMaximumSize
            [[PHCachingImageManager defaultManager] requestImageForAsset:asset targetSize:CGSizeMake(WIDTH/4, HEIGHT/4) contentMode:PHImageContentModeAspectFit options:option resultHandler:^(UIImage * _Nullable image, NSDictionary * _Nullable info) {
                NSString *types = @"0";  //0:照片 1:视频
                if(asset.mediaType == PHAssetMediaTypeImage)
                {
                    types = @"0";
                }
                else
                {
                    types = @"1";
                }
                NSDictionary *dic = @{@"image":image,@"type":types,@"times":@"0"};
                [imageArray addObject:dic];
                [selectArray addObject:@"0"];
            }];
        }
        
        //通知主线程刷新
        dispatch_async(dispatch_get_main_queue(), ^{
            //回调或者说是通知主线程刷新
            [myCollectionView reloadData];
            [self.view hideToastActivity];
            page++;
            ready = YES;
        });
    });
}



/**
 上滑和下拉操作手势实现方法
 */
- (void)handleSwipeFrom:(UISwipeGestureRecognizer*)recognizer
{
    if(recognizer.direction ==UISwipeGestureRecognizerDirectionUp) //上拉
    {
        if(!UPorDown)
        {
            CGFloat yy = toolView.frame.origin.y;
            if(yy>100)
            {
                [UIView animateWithDuration:0.5 animations:^{
                    toolView.transform = CGAffineTransformMakeTranslation(0, -yy+kStatusBarHeight);
                    bottomV.transform = CGAffineTransformMakeTranslation(0, -yy+kStatusBarHeight);
                    myCollectionView.frame = CGRectMake(0, 0, WIDTH, HEIGHT-44-kStatusBarHeight);
                }completion:^(BOOL finished){
                }];
            }
            
            UPorDown = YES;
        }
    }
    else if(recognizer.direction ==UISwipeGestureRecognizerDirectionDown)  //下滑
    {
        if(UPorDown)
        {
            if(isTop)
            {
                [UIView animateWithDuration:0.5 animations:^{
                    toolView.transform = CGAffineTransformMakeTranslation(0, 0);
                    bottomV.transform = CGAffineTransformMakeTranslation(0, 0);
                }completion:^(BOOL finished){
                    myCollectionView.frame = CGRectMake(0, 0, WIDTH, 221+kSafeAreaBottomHeight);
                }];
                UPorDown = NO;
            }
            
        }
    }
}

#pragma mark -手势协议方法
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if([NSStringFromClass([touch.view class]) isEqualToString:@"UIView"])
    {
        UIView *vies = touch.view;
        if(vies.tag == 88)
        {
            isTop = YES;
        }
    }
    if([NSStringFromClass([touch.view class]) isEqual:@"UICollectionView"])
    {
        return NO;
    }
    else
    {
        return YES;
    }
}

/**
 滚动过程中实现的方法
 */
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGPoint localPoint = scrollView.contentOffset;
    if(localPoint.y <= 0)
    {
        isTop = YES;
    }
    else
    {
        isTop = NO;
        if(localPoint.y>(page+1)*3800)  //还未到达最底部就开始加载下200条，预防卡顿
        {
            if(ready)
            {
                [self footerClick];
            }
        }
    }
}

#pragma mark  CollectionView协议方法实现
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

/**
 设置CollectionView每组所包含的个数
 */
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return imageArray.count;
}

/**
 设置CollectionCell的内容
 */
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    HobbiesCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"HobbiesCollectionViewCell" forIndexPath:indexPath];
    cell.bgImageView.image = [imageArray[indexPath.row] objectForKey:@"image"];
    if([[imageArray[indexPath.row] objectForKey:@"type"] isEqualToString:@"0"])  //照片类型，隐藏视频相关控件
    {
        cell.playImageView.hidden = YES;
        cell.playMengView.hidden = YES;
        cell.playTimeLabel.hidden = YES;
    }
    else   //视频类型
    {
        cell.playImageView.hidden = NO;
        cell.playMengView.hidden = NO;
        cell.playTimeLabel.hidden = NO;
        if([[imageArray[indexPath.row] objectForKey:@"times"] isEqualToString:@"0"])
        {   //异步获取视频时长
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                // 处理耗时操作的代码块...
                PHAsset *asset = [phArray objectAtIndex:indexPath.row];
                __block int seconds;
                [[TZImageManager manager] getVideoWithAsset:asset completion:^(AVPlayerItem *playerItem, NSDictionary *info) {
                    AVAsset *avasset = playerItem.asset;
                    AVURLAsset *urlAsset = (AVURLAsset *)avasset;
                    CMTime time = [urlAsset duration];
                    seconds = (int)time.value/time.timescale;
                    NSDictionary *dic = @{@"image":[imageArray[indexPath.row] objectForKey:@"image"],@"type":[imageArray[indexPath.row] objectForKey:@"type"],@"times":[NSString stringWithFormat:@"%d",seconds]};
                    [imageArray replaceObjectAtIndex:indexPath.row withObject:dic];
                }];
                //通知主线程刷新
                dispatch_async(dispatch_get_main_queue(), ^{
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [myCollectionView reloadData];
                    });
                });
            });
        }
        else
        {
            cell.playTimeLabel.text = [self timeEdit:[NSString stringWithFormat:@"%@",[imageArray[indexPath.row] objectForKey:@"times"]]];
        }
    }
    
    //处理选择后的显示
    if([selectArray[indexPath.row] isEqualToString:@"0"])
    {
        cell.selectImageView.backgroundColor = [UIColor clearColor];
        cell.cellNumLabel.text = @"";
        cell.selectImageView.image = [UIImage imageNamed:@"noSelect"];
    }
    else
    {
        cell.selectImageView.backgroundColor = [UIColor colorWithRed:(255)/255.0 green:(175)/255.0 blue:(33)/255.0 alpha:1.0];
        cell.selectImageView.image = nil;
        cell.cellNumLabel.text = selectArray[indexPath.row];
    }
    cell.selectImageView.hidden = NO;
    cell.selectBtn.tag = indexPath.row;
    [cell.selectBtn addTarget:self action:@selector(selectBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
}

/**
 定义每个UICollectionView的大小
 */
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return  CGSizeMake(WIDTH/4-1,WIDTH/4-1);
}

/**
 定义整个CollectionViewCell与整个View的间距
 */
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(1, 1, 1, 1);//（上、左、下、右）
}

/**
 定义每个UICollectionView的横向间距
 */
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 0;
}

/**
 定义每个UICollectionView的纵向间距
 */
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 0;
}

/**
 点击CollectionView触发事件
 */
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if([[imageArray[indexPath.row] objectForKey:@"type"] isEqualToString:@"0"]) //照片
    {
        [self lookImage:indexPath.row];
    }
    else
    {
        [self lookVideo:indexPath.row];
    }
}

/**
 设置CollectionViewCell是否可以被点击
 */
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

#pragma mark 时间格式处理
-(NSString *)timeEdit:(NSString *)times
{
    int timeNum = [times intValue];
    if(timeNum<10)
    {
        return [NSString stringWithFormat:@"00:0%d",timeNum];
    }
    else if (timeNum<60)
    {
        return [NSString stringWithFormat:@"00:%d",timeNum];
    }
    else
    {
        int a = timeNum%60;
        int b = timeNum/60;
        if(a<10)
        {
            if(b<10)
            {
                return [NSString stringWithFormat:@"0%d:0%d",b,a];
            }
            else
            {
                return [NSString stringWithFormat:@"%d:0%d",b,a];
            }
        }
        else
        {
            if(b<10)
            {
                return [NSString stringWithFormat:@"0%d:%d",b,a];
            }
            else
            {
                return [NSString stringWithFormat:@"%d:%d",b,a];
            }
        }
    }
}

#pragma mark 查看图片
-(void)lookImage:(NSInteger )currentIndex
{
    YBImageBrowser *browser = [YBImageBrowser new];
    browser.dataSource = self;
    browser.currentIndex = currentIndex;
    //展示
    [browser show];
}

#pragma mark 查看视频
-(void)lookVideo:(NSInteger )currentIndex
{
    PHAsset *phAsset = phArray[currentIndex];
    if (phAsset.mediaType == PHAssetMediaTypeVideo) {
        PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
        options.version = PHImageRequestOptionsVersionCurrent;
        options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;

        PHImageManager *manager = [PHImageManager defaultManager];
        [manager requestAVAssetForVideo:phAsset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
            AVURLAsset *urlAsset = (AVURLAsset *)asset;

            NSURL *url = urlAsset.URL;
            NSString *urls = [NSString stringWithFormat:@"%@",url];
            VideoPlayViewController *playVC = [[VideoPlayViewController alloc] init];
            playVC.url = urls;
            [self presentViewController:playVC  animated:YES completion:nil];
        }];
    }
}

#pragma mark 选择视频或照片实现
-(void)selectBtnClicked:(UIButton *)sender
{
    if(nums == 0)
    {
        IorV = -1;
    }
    if([[imageArray[sender.tag] objectForKey:@"type"] isEqualToString:@"0"]) //照片
    {
        if(IorV == 1)
        {
            [self.view makeToast:@"视频和照片只能上传一种！" duration:2 position:CENTER];
            return;
        }
        IorV = 0;
        if([selectArray[sender.tag] isEqualToString:@"0"])
        {
            if(nums == 9)
            {
                [self.view makeToast:@"最多只能选择9张照片！" duration:2 position:CENTER];
                return;
            }
            nums++;
            [selectArray replaceObjectAtIndex:sender.tag withObject:[NSString stringWithFormat:@"%ld",(long)nums]];
            [myCollectionView reloadData];
        }
        else
        {
            if([selectArray[sender.tag] integerValue] == 9) //是最后一个只要刷新最后一条的数据
            {
                [selectArray replaceObjectAtIndex:sender.tag withObject:@"0"];
                [myCollectionView reloadData];
            }
            else
            {
                
                for(int i=0;i<selectArray.count;i++)
                {
                    NSInteger indexs = [selectArray[i] integerValue];
                    if(indexs>[selectArray[sender.tag] integerValue])
                    {
                        [selectArray replaceObjectAtIndex:i withObject:[NSString stringWithFormat:@"%ld",(long)indexs]];
                    }
                }
                [selectArray replaceObjectAtIndex:sender.tag withObject:@"0"];
                [myCollectionView reloadData];
            }
            nums--;
        }
    }
    else
    {
        if(IorV == 0)
        {
            [self.view makeToast:@"视频和照片只能上传一种！" duration:2 position:CENTER];
            return;
        }
        IorV = 1;
        if([selectArray[sender.tag] isEqualToString:@"0"])
        {
            if(nums == 1)
            {
                [self.view makeToast:@"最多只能选择1个视频！" duration:2 position:CENTER];
                return;
            }
            nums++;
            [selectArray replaceObjectAtIndex:sender.tag withObject:[NSString stringWithFormat:@"%ld",(long)nums]];
            [myCollectionView reloadData];
        }
        else
        {
            [selectArray replaceObjectAtIndex:sender.tag withObject:@"0"];
            [myCollectionView reloadData];
            nums -- ;
        }
    }
}

#pragma mark  -YBImageBrowserDataSource 代理实现赋值数据
- (NSUInteger)yb_numberOfCellForImageBrowserView:(YBImageBrowserView *)imageBrowserView {
    return phArray.count;
}

- (id<YBImageBrowserCellDataProtocol>)yb_imageBrowserView:(YBImageBrowserView *)imageBrowserView dataForCellAtIndex:(NSUInteger)index {
    YBImageBrowseCellData *data = [YBImageBrowseCellData new];
    data.phAsset = phArray[index];
    return data;
}
@end
