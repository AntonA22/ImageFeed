import UIKit
import Kingfisher

final class SingleImageViewController: UIViewController {

    var image: UIImage? {
        didSet {
            guard isViewLoaded else { return }
            updateImage()
        }
    }
    var fullImageURL: URL? {
        didSet {
            guard isViewLoaded else { return }
            loadFullSizeImage()
        }
    }

    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var scrollView: UIScrollView!

    @IBAction private func didTapBackButton() {
        dismiss(animated: true)
    }
    
    @IBAction private func didTapShareButton() {
        guard let image = imageView.image else { return }

        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)

        present(activityVC, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        scrollView.delegate = self
        scrollView.minimumZoomScale = 0.1
        scrollView.maximumZoomScale = 1.25

        updateImage()
        loadFullSizeImage()
    }

    private func updateImage() {
        guard let image else { return }

        imageView.image = image
        imageView.frame = CGRect(origin: .zero, size: image.size)
        scrollView.contentSize = image.size
        
        rescaleAndCenterImageInScrollView(image: image)
    }

    private func loadFullSizeImage() {
        guard let fullImageURL else { return }

        UIBlockingProgressHUD.show()
        imageView.kf.setImage(with: fullImageURL) { [weak self] result in
            UIBlockingProgressHUD.dismiss()
            guard let self else { return }

            switch result {
            case .success(let imageResult):
                self.image = imageResult.image
            case .failure:
                self.showError()
            }
        }
    }

    private func showError() {
        let alert = UIAlertController(
            title: "Что-то пошло не так. Попробовать ещё раз?",
            message: nil,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Не надо", style: .cancel))
        alert.addAction(
            UIAlertAction(title: "Повторить", style: .default) { [weak self] _ in
                self?.loadFullSizeImage()
            }
        )
        present(alert, animated: true)
    }
    
    private func rescaleAndCenterImageInScrollView(image: UIImage) {
        let minZoomScale = scrollView.minimumZoomScale
        let maxZoomScale = scrollView.maximumZoomScale
        view.layoutIfNeeded()
        let visibleRectSize = scrollView.bounds.size
        let imageSize = image.size
        let hScale = visibleRectSize.width / imageSize.width
        let vScale = visibleRectSize.height / imageSize.height
        let scale = min(maxZoomScale, max(minZoomScale, min(hScale, vScale)))
        scrollView.setZoomScale(scale, animated: false)
        scrollView.layoutIfNeeded()
        let newContentSize = scrollView.contentSize
        let x = (newContentSize.width - visibleRectSize.width) / 2
        let y = (newContentSize.height - visibleRectSize.height) / 2
        scrollView.setContentOffset(CGPoint(x: x, y: y), animated: false)
    }
}

extension SingleImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }
}
