import UIKit

let PICache = NSCache<AnyObject, AnyObject>()
let PostCache = NSCache<AnyObject, AnyObject>()


class CustomImageView : UIImageView {
    
    var profileImageUrl: URL?
    
    func profileImageCache(url: URL, userId: Int, completionBlock: @escaping (UIImage) -> () = {_ in }) {
        
        profileImageUrl = url
        
        image = nil
        if let imageFromCache = PICache.object(forKey: userId as AnyObject) as? UIImage {
            self.image = imageFromCache
            completionBlock(imageFromCache)
        }
        else {
            let request = URLRequest(url: url)
            URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
                if let response = data {
                    DispatchQueue.main.async {
                        guard let imageToCache = UIImage(data: response) else {return}
                        
                        if self.profileImageUrl == url {
                            self.image = imageToCache

                        }
                        
                        PICache.setObject(imageToCache, forKey: userId as AnyObject)
                        completionBlock(imageToCache)
                    }}
                
            }).resume()
        }
    }
    
    var postImageUrl: URL?
    
    func postImageCache(url: URL, postId: Int) {
        
        postImageUrl = url
        
        image = nil
        if let imageFromCache = PostCache.object(forKey: postId as AnyObject) as? UIImage {
            self.image = imageFromCache
        }
        else {
            let request = URLRequest(url: url)
            URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
                if let response = data {
                    DispatchQueue.main.async {
                        guard let imageToCache = UIImage(data: response) else {return}
                        
                        if self.postImageUrl == url {
                            self.image = imageToCache
                        }
                        
                        PostCache.setObject(imageToCache, forKey: postId as AnyObject)
                        
                    }}
            }).resume()
        }
    }
    
    func resetProfileImageForUser(image: UIImage, userId: Int){ // Should fix the image change issue.
        PICache.setObject(image, forKey: userId as AnyObject)
    }
    
    
}



