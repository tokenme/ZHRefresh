//  ZHRefreshAutoFooter.swift
//  Refresh
//
//  Created by SummerHF on 08/05/2018.
//
//
//  Copyright (c) 2018 SummerHF(https://github.com/summerhf)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit

/// 会自动刷新的上拉刷新控件
class ZHRefreshAutoFooter: ZHRefreshFooter {
    /// 是否自动刷新, 默认是`true`
    var automaticallyRefresh: Bool = true
    /// 当底部控件出现多少时就自动刷新(默认为1.0 也就是底部控件完全出现时, 才会自动刷新)
    var triggerAutomaticallyRefreshPercent: CGFloat = 1.0
    /// 是否每次拖拽一次只发一次请求, 默认是`false`
    var onlyRefreshPerDray: Bool = false
     /// 一个新的拖拽事件
    private var oneNewPan: Bool?

    // MARK: - 初始化

    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        /// 新的父控件
        if newSuperview != nil {
            if !self.isHidden {
                self.scrollView.zh_insertB += self.zh_h
            }
            /// 设置位置
            self.zh_y = self.scrollView.zh_contentH
        } else {
            /// 被移除
            if !self.isHidden {
                /// 恢复到原始状态
                self.scrollView.zh_insertB -= self.zh_h
            }
        }
    }

    // MARK: - override
    override func prepare() {
        super.prepare()
        /// 默认底部控件100%出现时才会自动刷新
        self.triggerAutomaticallyRefreshPercent = 1.0
        self.automaticallyRefresh = true
        /// 默认是offSet达到条件就发送请求(可连续)
        self.onlyRefreshPerDray = false
    }

    override func scrollViewContentSizeDid(change: [NSKeyValueChangeKey: Any]?) {
        super.scrollViewContentSizeDid(change: change)
        /// 设置位置
        self.zh_y = self.scrollView.zh_contentH
    }

    override func scrollViewContentOffsetDid(change: [NSKeyValueChangeKey: Any]) {
        super.scrollViewContentOffsetDid(change: change)
        if self.state != .idle || self.automaticallyRefresh || self.zh_y == 0 { return }
        /// 内容超过一个屏幕
        if self.scrollView.zh_insertT + self.scrollView.zh_contentH > self.scrollView.zh_contentH {
            let condition = scrollView.zh_offsetY >= scrollView.zh_contentH - scrollView.zh_h + self.zh_h * self.triggerAutomaticallyRefreshPercent + scrollView.zh_insertB - self.zh_h
            if condition {
                if let old = change[.oldKey] as? CGPoint, let new = change[.newKey] as? CGPoint {
                    if new.y <= old.y { return }
                    /// 当底部刷新控件完全显示时 才刷新
                    self.beginRefreshing()
                }
            }
        }
    }

    override func scrollViewPanStateDid(change: [NSKeyValueChangeKey: Any]) {
        super.scrollViewPanStateDid(change: change)
        if self.state != .idle { return }
        let state = self.scrollView.panGestureRecognizer.state
        /// 手松开
        if state == .ended {
            if scrollView.zh_insertT + scrollView.zh_contentH <= scrollView.zh_h {
                if scrollView.zh_offsetY >= -scrollView.zh_insertT {
                    self.beginRefreshing()
                }
            } else {
                /// 超出一个屏幕
                if scrollView.zh_offsetY >= scrollView.zh_contentH + scrollView.zh_insertB - scrollView.zh_h {
                    self.beginRefreshing()
                }
            }
        } else if state == .began {
            self.oneNewPan = true
        }
    }

    override func beginRefreshing() {
        guard let newPan = self.oneNewPan else { return }
        if !newPan && self.onlyRefreshPerDray { return }
        super.beginRefreshing()
        self.oneNewPan = false
    }

    override var state: ZHRefreshState {
        get {
            return super.state
        }
        set {
            guard let oldState = check(newState: newValue, oldState: state) else { return }
            super.state = newValue
            if newValue == .refreshing {
                self.executeRefreshingCallBack()
            } else if newValue == .nomoreData || newValue == .idle {
                if oldState == .refreshing {
                    if let endRefreshBlock = self.endRefreshingCompletionBlock {
                        endRefreshBlock()
                    }
                }
            }
        }
    }

    override var isHidden: Bool {
        didSet {
            if isHidden && !oldValue {
                self.state = .idle
                self.scrollView.zh_insertB -= self.zh_h
            } else if !isHidden && oldValue {
                self.scrollView.zh_insertB += self.zh_h
                /// 设置位置
                self.zh_y = scrollView.zh_contentH
            }
        }
    }
}
