###
# This source code is licensed under the terms of the
# GNU Affero General Public License found in the LICENSE file in
# the root directory of this source tree.
#
# Copyright (c) 2021-present Kaleidos INC
###

taiga = @.taiga

ProjectMenuDirective = (projectService, lightboxFactory) ->
    link = (scope, el, attrs, ctrl) ->
        # The navigation is a precompiled Angular element (elements.js). Keep
        # our extension in its maintained AngularJS wrapper, not the bundle.
        observedRoots = new WeakSet()
        observeRoot = (root) ->
            return unless root? and !observedRoots.has(root)
            observer.observe(root, {childList: true, subtree: true})
            observedRoots.add(root)

        renderCustomLinks = ->
            loader = el[0].querySelector('tg-legacy-loader')
            root = loader?.shadowRoot or loader
            observeRoot(root)
            navigation = root?.querySelector('tg-project-navigation')
            navigationRoot = navigation?.shadowRoot or navigation
            observeRoot(navigationRoot) if navigation?.shadowRoot
            menu = navigationRoot?.querySelector('.main-menu')
            return unless menu?
            # Styles must live inside the loader's shadow boundary too.
            unless root.querySelector('[data-custom-links-styles]')
                stylesheet = document.createElement('link')
                stylesheet.rel = 'stylesheet'
                stylesheet.href = new URL('custom-project-links.css', document.baseURI).href
                stylesheet.setAttribute('data-custom-links-styles', '')
                root.appendChild(stylesheet)
            project = projectService.project
            links = []
            if project?.get('is_custom_links_activated')
                links = project.get('custom_links')?.toJS() or []
            signature = JSON.stringify(links)
            return if menu.getAttribute('data-custom-links') == signature

            for item in menu.querySelectorAll('[data-custom-project-link]')
                item.remove()
            menu.setAttribute('data-custom-links', signature)
            issues = menu.querySelector('a[href$="/issues"]')?.closest('li')
            for link in links
                try
                    url = new URL(link.url)
                catch
                    continue
                continue unless url.protocol in ['http:', 'https:']
                item = document.createElement('li')
                item.className = 'menu-option custom-project-link'
                item.setAttribute('data-custom-project-link', '')
                anchor = document.createElement('a')
                anchor.href = url.href
                anchor.title = link.name
                anchor.setAttribute('aria-label', link.name)
                anchor.target = if link.open_in_new_tab then '_blank' else '_self'
                anchor.rel = 'noopener noreferrer' if link.open_in_new_tab
                icon = document.createElement('span')
                icon.className = 'custom-project-link-icon'
                icon.setAttribute('aria-hidden', 'true')
                icon.textContent = '↗'
                label = document.createElement('span')
                label.className = 'custom-project-link-label'
                label.textContent = link.name
                anchor.appendChild(icon)
                anchor.appendChild(label)
                item.appendChild(anchor)
                menu.insertBefore(item, issues or null)

        observer = new MutationObserver(renderCustomLinks)
        observeRoot(el[0])
        customElements.whenDefined('tg-legacy-loader').then(renderCustomLinks)

        projectChange = () ->
            if projectService.project
                ctrl.show()
            else
                ctrl.hide()
            renderCustomLinks()

        scope.$watch ( () ->
            return projectService.project
        ), projectChange

        fixed = false
        topBarHeight = 48

        onScroll = () ->
            position = $(window).scrollTop()

            if position > topBarHeight && fixed == false
                el.find('.sticky-project-menu').addClass('unblock')
                fixed = true
            else if position == 0 && fixed == true
                el.find('.sticky-project-menu').removeClass('unblock')
                fixed = false

        window.addEventListener "scroll", onScroll
        scope.$on '$destroy', ->
            observer.disconnect()
            window.removeEventListener('scroll', onScroll)

    return {
        scope: {},
        controller: "ProjectMenu",
        controllerAs: "vm",
        templateUrl: "components/project-menu/project-menu.html",
        link: link
    }

ProjectMenuDirective.$inject = [
    "tgProjectService",
    "tgLightboxFactory"
]

angular.module("taigaComponents").directive("tgProjectMenu", ProjectMenuDirective)
