//
//  S3Uploader.swift
//  RxCognito
//
//  Created by Jaehong Yoo on 2021/03/08.
//

import Foundation
import SotoS3
import RxSwift

class S3Uploader {
    
    private let regions: Regions
    private let s3: S3
    
    init(awsClient: AWSClient, regions: Regions) {
        self.regions = regions
        
        self.s3 = S3(client: awsClient, region: regions.getRegion())
    }
    
    func putObject(bucket: String, key: String, data: Data) -> Completable {
        Completable.create { (observer) -> Disposable in
            let putObjectRequest = S3.PutObjectRequest(
                acl: .publicRead,
                body: AWSPayload.data(data),
                bucket: bucket,
                key: key
            )
            let request = self.s3.putObject(putObjectRequest)
            request.whenSuccess { (output) in
                observer(.completed)
            }
            request.whenFailure { (error) in
                observer(.error(error))
            }
            return Disposables.create()
        }
    }
}
