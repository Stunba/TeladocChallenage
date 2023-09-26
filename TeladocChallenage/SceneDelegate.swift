//
//  SceneDelegate.swift
//  TeladocChallenage
//
//  Created by Artem Bastun on 26/09/2023.
//

import UIKit
import Combine

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var rootComponent: VocabularyComponent?
    var cancellable: Cancellable?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let scene = (scene as? UIWindowScene) else { return }

        let rootComponent = VocabularyComponent.create()
        self.rootComponent = rootComponent

        let window = UIWindow(windowScene: scene)
        let navigationController = UINavigationController()
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        self.window = window
        
        let presenter = VocabularyComponentPresenter {
            navigationController.pushViewController($0, animated: false)
            return AnyCancellable { navigationController.popViewController(animated: false) }
        }
        self.cancellable = presenter.present(rootComponent)
    }
}

