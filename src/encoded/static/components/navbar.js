/** @jsx React.DOM */
'use strict';
var React = require('react');
var url = require('url');
var mixins = require('./mixins');

// Hide data from NavBarLayout
var NavBar = React.createClass({
    render: function() {
        var section = url.parse(this.props.href).pathname.split('/', 2)[1] || '';
        return NavBarLayout({
            loadingComplete: this.props.loadingComplete,
            portal: this.props.portal,
            section: section,
            session: this.props.session,
            user_actions: this.props.user_actions,
            href: this.props.href,
        });
    }
});


var NavBarLayout = React.createClass({

    render: function() {
        console.log('render navbar');
        var portal = this.props.portal;
        var section = this.props.section;
        var session = this.props.session;
        var user_actions = this.props.user_actions;
        return (
            <div id="navbar" className="navbar navbar-fixed-top navbar-inverse" role="navigation">
                <div className="container">
                    <div className="navbar-header">                        
                        <button type="button" className="navbar-toggle" data-toggle="collapse" data-target="#encode-navbar">
                            <span className="sr-only">Toggle navigation</span>
                            <span className="icon-bar"></span>
                            <span className="icon-bar"></span>
                            <span className="icon-bar"></span>
                        </button>
                        <a className="navbar-brand" href="/">{portal.portal_title}</a>
                    </div>
                    <div className="navbar-collapse collapse" id="encode-navbar">
                        <GlobalSections global_sections={portal.global_sections} section={section} />
                        {this.transferPropsTo(<UserActions />)}
                        {this.transferPropsTo(<Search />)}
                    </div>
                </div>
            </div>
        );
    }
});


var GlobalSections = React.createClass({
    render: function() {
        var section = this.props.section;
        var actions = this.props.global_sections.map(function (action) {
            var className = action['class'] || '';
            if (section == action.id) {
                className += ' active';
            }
            return (
                <li className={className} key={action.id}>
                    <a href={action.url}>{action.title}</a>
                </li>
            );
        });
        return <ul id="global-sections" className="nav navbar-nav">{actions}</ul>;
    }
});

var Search = React.createClass({
    render: function() {
        var id = url.parse(this.props.href, true);
        var searchTerm = id.query['searchTerm'] || '';
        return (
        	<form className="navbar-form pull-right" action="/search/">
    			<div className="search-wrapper">
    				<input className="form-control search-query" id="navbar-search" type="text" placeholder="Search ENCODE" 
                        ref="searchTerm" name="searchTerm" defaultValue={searchTerm} key={searchTerm} />
    			</div>
    		</form>
        );  
    }
});


var UserActions = React.createClass({
    render: function() {
        var session = this.props.session;
        var disabled = !this.props.loadingComplete;
        if (!(session && session['auth.userid'])) {
            return (
                <ul id="user-actions" className="nav navbar-nav navbar-right">
                    <li><a disabled={disabled} data-trigger="login" data-id="signin">Sign in</a></li>
                </ul>
            );
        }
        var actions = this.props.user_actions.map(function (action) {
            return (
                <li className={action['class']} key={action.id} role="presentation">
                    <a  role="menuitem" tabindex="-1" href={action.url || ''} data-bypass={action.bypass} data-trigger={action.trigger}>
                        {action.title}
                    </a>
                </li>
            );
        });
        var fullname = (session.user_properties && session.user_properties.title) || 'unknown';
        return (
            <ul id="user-actions" className="nav navbar-nav navbar-right">
                <li className="dropdown">
                    <a href="" className="dropdown-toggle" data-toggle="dropdown">{fullname}
                    <b className="caret"></b></a>
                        <ul className="dropdown-menu" role="menu">
                            {actions}
                        </ul>
                </li>
            </ul>
        );
    }
});

module.exports = NavBar;
